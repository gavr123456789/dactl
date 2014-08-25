[GtkTemplate (ui = "/org/coanda/dactl/ui/configuration-toolbar.ui")]
private class Dactl.ConfigurationToolbar : Gtk.HeaderBar {

    [GtkChild]
    private Gtk.Button back_button;

    [GtkChild]
    private Gtk.Image back_image;

    construct {
        title = "Configuration";

        back_image.icon_name = "go-previous-symbolic";
    }
}
