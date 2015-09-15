/* Copyright 2011-2015 Switchboard Locale Plug Developers
*
* This program is free software: you can redistribute it
* and/or modify it under the terms of the GNU Lesser General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with this program. If not, see http://www.gnu.org/licenses/.
*/

namespace LC {
    public static const string LANG = "LANG";
    public static const string NUMERIC = "LC_NUMERIC";
    public static const string TIME = "LC_TIME";
    public static const string MONETARY = "LC_MONETARY";
    public static const string MESSAGES = "LC_MESSAGES";
    public static const string PAPER = "LC_PAPER";
    public static const string NAME = "LC_NAME";
    public static const string ADDRESS = "LC_ADDRESS";
    public static const string MEASUREMENT = "LC_MEASUREMENT";
    public static const string TELEPHONE = "LC_TELEPHONE";
    public static const string IDENTIFICATION = "LC_IDENTIFICATION";
}

namespace SwitchboardPlugLocale {
    public class Plug : Switchboard.Plug {
        Gtk.Grid grid;
        Widgets.LocaleView view;

        public Installer.UbuntuInstaller installer;
        LocaleManager lm;

        public Gtk.InfoBar infobar;
        public Gtk.InfoBar permission_infobar;
        public Gtk.InfoBar missing_lang_infobar;
        public Widgets.InstallInfoBar install_infobar;

        public Plug () {
            Object (category: Category.PERSONAL,
                    code_name: "system-pantheon-locale",
                    display_name: _("Language & Region"),
                    description: _("Install languages, set region, and choose date &amp; currency formats"),
                    icon: "preferences-desktop-locale");
        }

        public override Gtk.Widget get_widget () {
            if (grid == null) {
                installer = new Installer.UbuntuInstaller ();
                grid = new Gtk.Grid ();

                setup_ui ();
                setup_info ();
            }
            return grid;
        }

        private void reload () {
            var langs = Utils.get_installed_languages ();
            var locales = Utils.get_installed_locales ();

            view.list_box.reload_languages (langs);
            view.locale_setting.reload_formats (locales);
            installer.check_missing_languages ();
        }

        void setup_info () {
            lm = LocaleManager.get_default ();

            lm.connected.connect (() => {
                reload ();

                infobar.no_show_all = true;
                infobar.hide ();
            });

            installer.install_finished.connect ((langcode) => {
                reload ();
                view.make_sensitive (true);
            });
            installer.remove_finished.connect ((langcode) => {
                reload ();
                view.make_sensitive (true);
            });
            installer.check_missing_finished.connect ((missing) => {
                if (missing.length > 0) {
                    missing_lang_infobar.show ();
                    missing_lang_infobar.show_all ();
                } else {
                    missing_lang_infobar.hide ();
                }
            });
            installer.progress_changed.connect ((progress) => {
                install_infobar.set_progress (progress);
                install_infobar.set_cancellable (installer.install_cancellable);
                install_infobar.set_transaction_mode (installer.transaction_mode);
            });
        }

        public override void shown () {

        }

        public override void hidden () {

        }

        public override void search_callback (string location) {

        }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            return new Gee.TreeMap<string, string> (null, null);
        }

        // Wires up and configures initial UI
        private void setup_ui () {
            grid.column_homogeneous = true;

            //Gtk.InfoBar for informing about necessary log-out/log-in
            infobar = new Gtk.InfoBar ();
            infobar.message_type = Gtk.MessageType.WARNING;
            infobar.no_show_all = true;
            var content = infobar.get_content_area () as Gtk.Container;
            var label = new Gtk.Label (_("Some changes will not take effect until you log out"));
            content.add (label);

            //Gtk.InfoBar for language support installation
            missing_lang_infobar = new Gtk.InfoBar ();
            missing_lang_infobar.message_type = Gtk.MessageType.WARNING;
            var missing_content = missing_lang_infobar.get_content_area () as Gtk.Box;
            var missing_label = new Gtk.Label (_("Language support is not installed completely"));

            var install_missing = new Gtk.Button.with_label (_("Complete Installation"));
            install_missing.clicked.connect (() => {
                missing_lang_infobar.hide ();
                installer.install_missing_languages ();
            });
            missing_content.pack_start (missing_label, false);
            missing_content.pack_end (install_missing, false);

            //Gtk.InfoBar for "one-click" administrative permissions
            permission_infobar = new Gtk.InfoBar ();
            permission_infobar.message_type = Gtk.MessageType.INFO;

            var area_infobar = permission_infobar.get_action_area () as Gtk.Container;
            var lock_button = new Gtk.LockButton (Utils.get_permission ());
            area_infobar.add (lock_button);

            var content_infobar = permission_infobar.get_content_area () as Gtk.Container;
            var label_infobar = new Gtk.Label (_("Some settings require administrator rights to be changed"));
            content_infobar.add (label_infobar);

            permission_infobar.show_all ();

            //Custom InstallInfoBar widget for language installation progress
            install_infobar = new Widgets.InstallInfoBar ();
            install_infobar.no_show_all = true;
            install_infobar.cancel_clicked.connect (installer.cancel_install);

            //connect polkit permission to hiding the permission infobar
            Utils.get_permission ().notify["allowed"].connect (() => {
                if (Utils.get_permission ().allowed) {
                    permission_infobar.no_show_all = true;
                    permission_infobar.hide ();
                }
            });

            view = new Widgets.LocaleView (this);

            grid.attach (infobar, 0, 0, 1, 1);
            grid.attach (missing_lang_infobar, 0, 1, 1, 1);
            grid.attach (permission_infobar, 0, 2, 1, 1);
            grid.attach (install_infobar, 0, 3, 1, 1);
            grid.attach (view, 0, 4, 1, 1);
            grid.show ();
        }

        public void on_install_language (string language) {
            view.make_sensitive (false);
            installer.install (language);
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Locale plug");
    var plug = new SwitchboardPlugLocale.Plug ();
    return plug;
}
