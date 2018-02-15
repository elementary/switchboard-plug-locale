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
    public const string LANG = "LANG";
    public const string NUMERIC = "LC_NUMERIC";
    public const string TIME = "LC_TIME";
    public const string MONETARY = "LC_MONETARY";
    public const string MESSAGES = "LC_MESSAGES";
    public const string PAPER = "LC_PAPER";
    public const string NAME = "LC_NAME";
    public const string ADDRESS = "LC_ADDRESS";
    public const string MEASUREMENT = "LC_MEASUREMENT";
    public const string TELEPHONE = "LC_TELEPHONE";
    public const string IDENTIFICATION = "LC_IDENTIFICATION";
}

namespace SwitchboardPlugLocale {
    public class Plug : Switchboard.Plug {
        Gtk.Grid grid;
        Widgets.LocaleView view;

        public Installer.UbuntuInstaller installer;

        public Gtk.InfoBar infobar;
        public Gtk.InfoBar permission_infobar;
        public Gtk.InfoBar missing_lang_infobar;
        public Widgets.InstallInfoBar install_infobar;

        public Plug () {
            var settings = new Gee.TreeMap<string, string?> (null, null);
            settings.set ("language", null);

            Utils.init ();
            Object (category: Category.PERSONAL,
                    code_name: "system-pantheon-locale",
                    display_name: _("Language & Region"),
                    description: _("Manage languages, and configure region and format"),
                    icon: "preferences-desktop-locale",
                    supported_settings: settings);
        }

        public override Gtk.Widget get_widget () {
            if (grid == null) {
                installer = new Installer.UbuntuInstaller ();

                setup_ui ();
                setup_info ();
            }

            return grid;
        }

        private async void reload () {
            new Thread<void*> ("load-lang-data", () => {
                var langs = Utils.get_installed_languages ();
                var locales = Utils.get_installed_locales ();

                Idle.add (() => {
                    view.list_box.reload_languages (langs);
                    view.locale_setting.reload_formats (locales);
                    return false;
                });

                return null;
            });

            yield installer.check_missing_languages ();
        }

        void setup_info () {
            unowned LocaleManager lm = LocaleManager.get_default ();
            if (lm.is_connected) {
                reload.begin ();

                infobar.no_show_all = true;
                infobar.hide ();
            }

            installer.install_finished.connect ((langcode) => {
                reload.begin ();
                view.make_sensitive (true);
            });

            installer.remove_finished.connect ((langcode) => {
                reload.begin ();
                view.make_sensitive (true);
            });

            installer.check_missing_finished.connect (on_check_missing_finished);
            installer.progress_changed.connect (on_progress_changed);
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
            grid = new Gtk.Grid ();
            grid.column_homogeneous = true;

            // Gtk.InfoBar for informing about necessary log-out/log-in
            infobar = new Gtk.InfoBar ();
            infobar.message_type = Gtk.MessageType.WARNING;
            infobar.no_show_all = true;
            var content = infobar.get_content_area () as Gtk.Container;
            var label = new Gtk.Label (_("Some changes will not take effect until you log out"));
            content.add (label);

            // Gtk.InfoBar for language support installation
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

            // Gtk.InfoBar for "one-click" administrative permissions
            permission_infobar = new Gtk.InfoBar ();
            permission_infobar.message_type = Gtk.MessageType.INFO;

            var area_infobar = permission_infobar.get_action_area () as Gtk.Container;
            var lock_button = new Gtk.LockButton (Utils.get_permission ());
            area_infobar.add (lock_button);

            var content_infobar = permission_infobar.get_content_area () as Gtk.Container;
            var label_infobar = new Gtk.Label (_("Some settings require administrator rights to be changed"));
            content_infobar.add (label_infobar);

            permission_infobar.show_all ();

            // Custom InstallInfoBar widget for language installation progress
            install_infobar = new Widgets.InstallInfoBar ();
            install_infobar.no_show_all = true;
            install_infobar.cancel_clicked.connect (installer.cancel_install);

            // connect polkit permission to hiding the permission infobar
            var permission = Utils.get_permission ();
            permission.notify["allowed"].connect (() => {
                if (permission.allowed) {
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

        private void on_check_missing_finished (string[] missing) {
            if (missing.length > 0) {
                missing_lang_infobar.show ();
                missing_lang_infobar.show_all ();
            } else {
                missing_lang_infobar.hide ();
            }
        }

        private void on_progress_changed (int progress) {
            install_infobar.progress = progress;
            install_infobar.is_cancellable = installer.install_cancellable;
            install_infobar.transaction_mode = installer.transaction_mode;
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Locale plug");
    var plug = new SwitchboardPlugLocale.Plug ();
    return plug;
}
