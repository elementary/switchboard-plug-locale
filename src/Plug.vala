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

namespace SwitchboardPlugLocale {
    public class Plug : Switchboard.Plug {
        Gtk.Grid grid;
        Widgets.LocaleView view;

        public Gtk.InfoBar infobar;
        public Gtk.InfoBar permission_infobar;
        public Gtk.InfoBar missing_lang_infobar;

        private Installer.UbuntuInstaller installer;
        private ProgressDialog progress_dialog = null;

        private Gee.ArrayList<string> langs;

        public Plug () {
            GLib.Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
            GLib.Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");

            var settings = new Gee.TreeMap<string, string?> (null, null);
            settings.set ("language", null);

            Object (category: Category.PERSONAL,
                    code_name: "io.elementary.switchboard.locale",
                    display_name: _("Language & Region"),
                    description: _("Manage languages, and configure region and format"),
                    icon: "preferences-desktop-locale",
                    supported_settings: settings);
        }

        public override Gtk.Widget get_widget () {
            if (grid == null) {
                Utils.init ();
                installer = Installer.UbuntuInstaller.get_default ();

                setup_ui ();
                setup_info ();
            }

            return grid;
        }

        private async void reload () {
            new Thread<void*> ("load-lang-data", () => {
                langs = Utils.get_installed_languages ();

                Idle.add (() => {
                    view.list_box.reload_languages (langs);
                    view.locale_setting.reload_formats (langs);
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

                infobar.revealed = false;
            }

            installer.install_finished.connect ((langcode) => {
                langs.add (langcode);
                reload.begin ();
            });

            installer.remove_finished.connect ((langcode) => {
                langs.remove (langcode);
                reload.begin ();
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
            var search_results = new Gee.TreeMap<string, string> (
                (GLib.CompareDataFunc<string>)strcmp,
                (Gee.EqualDataFunc<string>)str_equal
            );
            search_results.set ("%s → %s".printf (display_name, _("Region")), "");
            search_results.set ("%s → %s".printf (display_name, _("Formats")), "");
            search_results.set ("%s → %s".printf (display_name, _("Temperature")), "");
            return search_results;
        }

        // Wires up and configures initial UI
        private void setup_ui () {
            // Gtk.InfoBar for informing about necessary log-out/log-in
            var label = new Gtk.Label (_("Some changes will not take effect until you log out"));
            infobar = new Gtk.InfoBar ();
            infobar.message_type = Gtk.MessageType.WARNING;
            infobar.revealed = false;
            infobar.get_content_area ().add (label);

            // Gtk.InfoBar for language support installation
            var missing_label = new Gtk.Label (_("Language support is not installed completely"));

            missing_lang_infobar = new Gtk.InfoBar ();
            missing_lang_infobar.message_type = Gtk.MessageType.WARNING;
            missing_lang_infobar.revealed = false;
            missing_lang_infobar.add_button (_("Complete Installation"), 0);
            missing_lang_infobar.get_content_area ().add (missing_label);

            view = new Widgets.LocaleView (this);

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.add (infobar);
            grid.add (missing_lang_infobar);
            grid.add (view);
            grid.show ();

            missing_lang_infobar.response.connect (() => {
                missing_lang_infobar.revealed = false;
                installer.install_missing_languages ();
            });
        }

        private void on_check_missing_finished (string[] missing) {
            if (missing.length > 0) {
                missing_lang_infobar.show_all ();
                missing_lang_infobar.revealed = true;
            } else {
                missing_lang_infobar.revealed = false;
            }
        }

        private void on_progress_changed (int progress) {
            if (progress_dialog != null) {
                progress_dialog.progress = progress;
                return;
            }

            progress_dialog = new ProgressDialog ();
            progress_dialog.progress = progress;
            progress_dialog.transient_for = (Gtk.Window) grid.get_toplevel ();
            progress_dialog.run ();
            progress_dialog = null;
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Locale plug");
    var plug = new SwitchboardPlugLocale.Plug ();
    return plug;
}
