/* Copyright 2015 Switchboard Locale Plug Developers
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

namespace SwitchboardPlugLocale.Widgets {
    public class LocaleView : Gtk.Box {
        private Gtk.Box sidebar;

        public LanguageListBox list_box;
        public LocaleSetting locale_setting;
        public weak Plug plug { get; construct; }

        public LocaleView (Plug plug) {
            Object (plug: plug);
        }

        construct {
            var locale_manager = LocaleManager.get_default ();

            list_box = new LanguageListBox ();

            var scroll = new Gtk.ScrolledWindow () {
                child = list_box
            };

            var popover = new Widgets.InstallPopover ();

            var add_button = new Gtk.MenuButton () {
                icon_name = "list-add-symbolic",
                popover = popover,
                tooltip_text = _("Install language")
            };

            var remove_button = new Gtk.Button.from_icon_name ("list-remove-symbolic") {
                tooltip_text = _("Remove language")
            };

            var action_bar = new Gtk.ActionBar ();
            action_bar.add_css_class (Granite.STYLE_CLASS_FLAT);
            action_bar.pack_start (add_button);
            action_bar.pack_start (remove_button);

            sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            sidebar.append (scroll);
            sidebar.append (action_bar);

            locale_setting = new LocaleSetting ();

            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
                start_child = sidebar,
                shrink_start_child = false,
                resize_start_child = false,
                end_child = locale_setting,
                shrink_end_child = false,
                position = 200
            };

            append (paned);

            list_box.listbox.row_selected.connect ((row) => {
                if (row == null) {
                    return;
                }

                var selected_language_code = list_box.get_selected_language_code ();
                var locales = Utils.get_locales_for_language_code (selected_language_code);

                debug ("reloading Settings widget for language '%s'".printf (selected_language_code));
                locale_setting.reload_locales (selected_language_code, locales);
                locale_setting.reload_labels (selected_language_code);

                if (locale_manager.get_user_language () in locales) {
                    remove_button.sensitive = false;
                } else {
                    remove_button.sensitive = true;
                }
            });

            unowned Installer.UbuntuInstaller installer = Installer.UbuntuInstaller.get_default ();

            installer.install_finished.connect (() => {
                make_sensitive (true);
            });

            installer.remove_finished.connect (() => {
                make_sensitive (true);
            });

            remove_button.clicked.connect (() => {
                if (!Utils.allowed_permission ()) {
                    return;
                }

                make_sensitive (false);
                installer.remove (list_box.get_selected_language_code ());
            });

            popover.language_selected.connect ((lang) => {
                if (!Utils.allowed_permission ()) {
                    return;
                }

                make_sensitive (false);
                installer.install (lang);
            });
        }

        private void make_sensitive (bool sensitive) {
            sidebar.sensitive = sensitive;
            locale_setting.sensitive = sensitive;
        }
    }
}
