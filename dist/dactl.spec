%global appid org.coanda.Dactl
%global schemaid org.coanda.dactl

Name:    dactl
Version: 0.4.2
Release: 1%{?dist}
Summary: Data Acquisition and Control Application

License: MIT
URL:     http://github.com/coanda/dactl
Source0: %{name}-%{version}.tar.xz

BuildRequires: gcc
BuildRequires: vala
BuildRequires: meson
BuildRequires: pkgconfig(gee-0.8)
BuildRequires: pkgconfig(glib-2.0)
BuildRequires: pkgconfig(gio-2.0)
BuildRequires: pkgconfig(gsl)
BuildRequires: pkgconfig(json-glib-1.0)
BuildRequires: pkgconfig(libpeas-1.0)
BuildRequires: pkgconfig(libsoup-2.4)
BuildRequires: pkgconfig(libxml-2.0)
BuildRequires: pkgconfig(comedilib)
BuildRequires: pkgconfig(gtk+-3.0)
BuildRequires: pkgconfig(gtksourceview-3.0)
BuildRequires: pkgconfig(libpeas-gtk-1.0)
BuildRequires: pkgconfig(librsvg-2.0)
BuildRequires: pkgconfig(webkit2gtk-4.0)

Requires: cld
Requires: comedilib
Requires: glib2
Requires: json-glib
Requires: libgee
Requires: libpeas
Requires: libsoup
Requires: libxml2
Requires: gtk3
Requires: gtksourceview3
Requires: libpeas-gtk
Requires: librsvg2
Requires: webkitgtk4

%description
Data acquisition and control software.

%prep
%autosetup -p1

%build
%meson
%meson_build

%install
%meson_install

%check
%meson_test
desktop-file-validate $RPM_BUILD_ROOT%{_datadir}/applications/%{appid}.desktop

%post
/usr/bin/glib-compile-schemas %{_datadir}/glib-2.0/schemas &> /dev/null || :
/usr/bin/update-desktop-database &> /dev/null || :
/bin/touch --no-create %{_datadir}/icons/hicolor &> /dev/null || :

%postun
/usr/bin/update-desktop-database &> /dev/null || :
if [ $1 -eq 0 ] ; then
    /bin/touch --no-create %{_datadir}/icons/hicolor &> /dev/null || :
    /usr/bin/gtk-update-icon-cache %{_datadir}/icons/hicolor &> /dev/null || :
fi

%posttrans
/usr/bin/gtk-update-icon-cache %{_datadir}/icons/hicolor &> /dev/null || :

%files
%license COPYING
%doc README.md
%{_bindir}/%{name}
%{_datadir}/applications/%{appid}.desktop
%{_datadir}/appdata/%{appid}.appdata.xml
%{_datadir}/dbus-1/services/%{appid}.service
%{_datadir}/glade/catalogs/dactlui.xml
%{_datadir}/glib-2.0/schemas/%{schemaid}.gschema.xml
%{_datadir}/icons/hicolor/**/apps/%{appid}.png

%changelog
* Fri Mar 23 2018 - 0.1.0-1
- initial spec