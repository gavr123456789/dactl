private static bool cli = false;
private static bool verbose = false;
private static bool version = false;

private const GLib.OptionEntry[] local_options = {{
    "cli", 'c', 0, OptionArg.NONE, ref cli,
    "Start the application with a command line interface", null
},{
    "verbose", 'v', 0, OptionArg.NONE, ref verbose,
    "Provide verbose debugging output.", null
},{
    "version", 'V', 0, OptionArg.NONE, ref version,
    "Display version number.", null
},{
    null
}};

private static void parse_local_args (ref unowned string[] args) {
    var opt_context = new OptionContext (Dactl.Config.PACKAGE_NAME);
    opt_context.set_ignore_unknown_options (true);
    opt_context.set_help_enabled (false);
    opt_context.add_main_entries (local_options, null);

    try {
        opt_context.parse (ref args);
    } catch (OptionError e) {
    }

    if (version) {
        stdout.printf ("%s - version %s\n", args[0], Dactl.Config.PACKAGE_VERSION);
        Posix.exit (0);
    }
}

internal class Dactl.Main : GLib.Object {

    private static int PLUGIN_TIMEOUT = 5;

    private Dactl.Application app;
    private Dactl.PluginLoader plugin_loader;
    private Dactl.LogHandler log_handler;

    private int exit_code;

    public bool need_restart;

    private Main () throws GLib.Error {
        GLib.Environment.set_application_name (_(Config.PACKAGE_NAME));

        this.log_handler = Dactl.LogHandler.get_default ();
        this.plugin_loader = new Dactl.PluginLoader ();

        this.exit_code = 0;

        app = new Dactl.UI.Application ();

        app.closed.connect (() => {
            app = null;
        });

        this.plugin_loader.plugin_available.connect (this.on_plugin_loaded);

        Unix.signal_add (Posix.SIGHUP,  () => { this.restart (); return true; });
        Unix.signal_add (Posix.SIGINT,  () => { this.exit (0);   return true; });
        Unix.signal_add (Posix.SIGTERM, () => { this.exit (0);   return true; });
    }

    /**
     * XXX should implement a state dump to capture errors and configuration
     *     when this happens
     */
    public void exit (int exit_code) {
        this.exit_code = exit_code;
        (app as Dactl.UI.Application).shutdown ();
    }

    public void restart () {
        this.need_restart = true;
        this.exit (0);
    }

    private int run (string[] args) {
        message (_("Dactl v%s starting..."), Config.PACKAGE_VERSION);
        app.launch (args);

        return this.exit_code;
    }

    internal void dbus_available () {
        this.plugin_loader.load_modules ();

        var timeout = PLUGIN_TIMEOUT;
        try {
            /*
             *var config = MetaConfig.get_default ();
             *timeout = config.get_int ("plugin",
             *                          "TIMEOUT",
             *                          PLUGIN_TIMEOUT,
             *                          int.MAX);
             */
        } catch (Error error) {};

        Timeout.add_seconds (timeout, () => {
            if (this.plugin_loader.list_plugins ().size == 0) {
                warning (ngettext ("No plugins found in %d second; giving up...",
                                   "No plugins found in %d seconds; giving up...",
                                   PLUGIN_TIMEOUT),
                         PLUGIN_TIMEOUT);

                this.exit (-82);
            }

            return false;
        });
    }

    private void on_plugin_loaded (PluginLoader plugin_loader,
                                   Plugin       plugin) {
        /*
         *var iterator = this.factories.iterator ();
         *while (iterator.next ()) {
         *    this.create_device.begin (plugin, iterator.get ());
         *}
         */
    }

    private static int main (string[] args) {

        Dactl.Main main = null;
        DBusService service = null;

        var original_args = args;

        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Config.GETTEXT_PACKAGE);

        try {
            //Cld.init (args);

            parse_local_args (ref args);

            main = new Dactl.Main ();
            service = new Dactl.DBusService (main);
            service.publish ();
        } catch (GLib.Error err) {
            error ("%s", err.message);
        }

        /* Setup the application view */
        /*
         *if (cli) {
         *    GLib.message ("CLI application requested");
         *    app = new Dactl.CLI.Application ();
         *} else {
         *    GLib.message ("UI application requested");
         *    app = new Dactl.UI.Application ();
         *}
         */

        /* Launch the application */
        int exit_code = main.run (args);

        if (service != null) {
            service.unpublish ();
        }

        if (main.need_restart) {
            Posix.execvp (original_args[0], original_args);
        }

        return exit_code;
    }
}
