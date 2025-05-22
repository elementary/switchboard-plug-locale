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
        private Gee.ArrayList<string> langs;
        private Installer.UbuntuInstaller installer;
        private LanguageListBox list_box;
        private LocaleSetting locale_setting;
        private ProgressDialog progress_dialog = null;

        construct {
            list_box = new LanguageListBox ();

            var scroll = new Gtk.ScrolledWindow () {
                child = list_box,
                hscrollbar_policy = NEVER
            };

            var headerbar = new Adw.HeaderBar () {
                show_end_title_buttons = false,
                show_title = false
            };

            var install_label = new Gtk.Label (_("Install Language"));

            var add_box = new Gtk.Box (HORIZONTAL, 0);
            add_box.append (new Gtk.Image.from_icon_name ("list-add-symbolic"));
            add_box.append (install_label);

            var add_button = new Gtk.Button () {
                child = add_box,
                has_frame = false
            };
            install_label.mnemonic_widget = add_button;

            var remove_button = new Gtk.Button.from_icon_name ("list-remove-symbolic") {
                tooltip_text = _("Remove language")
            };

            var action_bar = new Gtk.ActionBar ();
            action_bar.pack_start (add_button);
            action_bar.pack_start (remove_button);

            var toolbarview = new Adw.ToolbarView () {
                content = scroll,
                bottom_bar_style = RAISED
            };
            toolbarview.add_top_bar (headerbar);
            toolbarview.add_bottom_bar (action_bar);

            var sidebar = new Sidebar ();
            sidebar.append (toolbarview);

            locale_setting = new LocaleSetting ();

            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
                start_child = sidebar,
                shrink_start_child = false,
                resize_start_child = false,
                end_child = locale_setting,
                shrink_end_child = false
            };

            var sss = SettingsSchemaSource.get_default ().lookup ("io.elementary.settings", true);
            if (sss != null && sss.has_key ("sidebar-position")) {
                var settings = new Settings ("io.elementary.settings");
                settings.bind ("sidebar-position", paned, "position", DEFAULT);
            }

            append (paned);

            list_box.listbox.row_selected.connect ((row) => {
                unowned var locale_manager = LocaleManager.get_default ();
                if (row == null) {
                    return;
                }

                var selected_language_code = list_box.get_selected_language_code ();
                var selected_language_name = list_box.get_selected_language_name ();
                var locales = Utils.get_locales_for_language_code (selected_language_code);

                debug ("reloading Settings widget for language '%s'".printf (selected_language_code));
                locale_setting.reload_locales.begin (selected_language_code, locales);
                locale_setting.reload_labels (selected_language_name);

                if (locale_manager.get_user_language () in locales) {
                    remove_button.sensitive = false;
                } else {
                    remove_button.sensitive = true;
                }
            });

            installer = Installer.UbuntuInstaller.get_default ();

            LocaleManager.get_default ().notify["is-connected"].connect (() => reload.begin ());

            installer.progress_changed.connect (on_progress_changed);

            installer.install_finished.connect ((langcode) => {
                reload.begin ();
            });

            installer.remove_finished.connect ((langcode) => {
                reload.begin ();
            });

            remove_button.clicked.connect (() => {
                installer.remove.begin (list_box.get_selected_language_code (), (obj, res) => {
                    try {
                        installer.remove.end (res);
                    } catch (Error e) {
                        if (e.matches (GLib.DBusError.quark (), GLib.DBusError.ACCESS_DENIED)) {
                            return;
                        }

                        var dialog = new Granite.MessageDialog (
                            _("Couldn't remove language pack"),
                            e.message,
                            new ThemedIcon ("preferences-desktop-locale")
                        ) {
                            badge_icon = new ThemedIcon ("dialog-error"),
                            modal = true,
                            transient_for = ((Gtk.Application) Application.get_default ()).active_window
                        };
                        dialog.present ();
                        dialog.response.connect (dialog.destroy);
                    }
                });
            });

            add_button.clicked.connect (() => {
                var install_dialog = new Widgets.InstallDialog () {
                    transient_for = (Gtk.Window) get_root ()
                };
                install_dialog.present ();
            });
        }

        private async void reload () {
            new Thread<void*> ("load-lang-data", () => {
                langs = Utils.get_installed_languages ();

                Idle.add (() => {
                    list_box.reload_languages (langs);
                    locale_setting.reload_formats (langs);
                    return false;
                });

                return null;
            });

            yield installer.check_missing_languages ();
        }

        private void on_progress_changed (int progress) {
            if (progress_dialog != null) {
                progress_dialog.progress = progress;
                return;
            }

            progress_dialog = new ProgressDialog () {
                modal = true,
                progress = progress,
                transient_for = (Gtk.Window) get_root ()
            };
            progress_dialog.present ();

            progress_dialog.response.connect (() => {
                progress_dialog.destroy ();
                progress_dialog = null;
            });
        }

        // Workaround to set styles
        private class Sidebar : Gtk.Box {
            class construct {
                set_css_name ("settingssidebar");
            }

            construct {
                add_css_class (Granite.STYLE_CLASS_SIDEBAR);
            }
        }
    }
}
