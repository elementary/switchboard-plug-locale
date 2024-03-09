/* Copyright 2011-2018 elementary LLC. (https://elementary.io)
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
    public class LocaleSetting : Switchboard.SettingsPage {
        private Gtk.Button set_button;
        private Gtk.InfoBar missing_lang_infobar;
        private Gtk.InfoBar restart_infobar;
        private Gtk.DropDown format_dropdown;
        private Gtk.DropDown region_dropdown;
        private GLib.ListStore format_list;
        private GLib.ListStore locale_list;

        private LocaleManager lm;
        private Preview preview;
        private string language;
        private Gtk.Label region_endlabel;

        private static GLib.Settings? temperature_settings = null;

        public LocaleSetting () {
            Object (icon: new ThemedIcon ("preferences-desktop-locale"));
        }

        construct {
            lm = LocaleManager.get_default ();

            format_list = new GLib.ListStore (typeof (Locale));
            locale_list = new GLib.ListStore (typeof (Locale));

            var expression = new Gtk.PropertyExpression (
                typeof (Locale),
                null,
                "name"
            );

            region_dropdown = new Gtk.DropDown (locale_list, null) {
                enable_search = true,
                expression = expression,
                search_match_mode = SUBSTRING
            };
            region_dropdown.notify["selected"].connect (compare);

            format_dropdown = new Gtk.DropDown (format_list, null) {
                enable_search = true,
                expression = expression,
                search_match_mode = SUBSTRING
            };
            format_dropdown.notify["selected"].connect (() => {
                on_format_changed ();
                compare ();
            });

            preview = new Preview () {
                halign = CENTER
            };
            preview.margin_bottom = 12;
            preview.margin_top = 12;

            region_endlabel = new Gtk.Label (_("Region:")) {
                halign = Gtk.Align.END
            };

            var formats_label = new Gtk.Label (_("Formats:")) {
                halign = Gtk.Align.END
            };

            var missing_label = new Gtk.Label (_("Language support is not installed completely"));

            missing_lang_infobar = new Gtk.InfoBar () {
                message_type = WARNING,
                revealed = false
            };
            missing_lang_infobar.add_button (_("Complete Installation"), 0);
            missing_lang_infobar.add_child (missing_label);
            missing_lang_infobar.add_css_class (Granite.STYLE_CLASS_FRAME);

            restart_infobar = new Gtk.InfoBar () {
                message_type = WARNING,
                revealed = false
            };
            restart_infobar.add_child (new Gtk.Label (_("Some changes will not take effect until you log out")));
            restart_infobar.add_css_class (Granite.STYLE_CLASS_FRAME);

            var content_area = new Gtk.Grid () {
                column_spacing = 6,
                row_spacing = 12
            };
            content_area.attach (region_endlabel, 0, 2);
            content_area.attach (region_dropdown, 1, 2, 2);
            content_area.attach (formats_label, 0, 3);
            content_area.attach (format_dropdown, 1, 3, 2);
            content_area.attach (preview, 0, 5, 3);
            content_area.attach (missing_lang_infobar, 0, 6, 3);
            content_area.attach (restart_infobar, 0, 7, 3);

            child = content_area;

            if (temperature_settings != null) {
                var temperature_label = new Gtk.Label (_("Temperature:")) {
                    halign = Gtk.Align.END
                };

                var celcius_radio = new Gtk.CheckButton.with_label (_("Celsius"));

                var fahrenheit_radio = new Gtk.CheckButton.with_label (_("Fahrenheit")) {
                    group = celcius_radio
                };

                var auto_radio = new Gtk.CheckButton () {
                    group = celcius_radio
                };

                content_area.attach (temperature_label, 0, 4);
                content_area.attach (celcius_radio, 1, 4);
                content_area.attach (fahrenheit_radio, 2, 4);

                var temp_setting = temperature_settings.get_string ("temperature-unit");

                if (temp_setting == "centigrade") {
                    celcius_radio.active = true;
                } else if (temp_setting == "fahrenheit") {
                    fahrenheit_radio.active = true;
                } else {
                    auto_radio.active = true;
                }

                celcius_radio.toggled.connect (() => {
                    if (celcius_radio.active) {
                        temperature_settings.set_string ("temperature-unit", "centigrade");
                    }
                });

                fahrenheit_radio.toggled.connect (() => {
                    if (fahrenheit_radio.active) {
                        temperature_settings.set_string ("temperature-unit", "fahrenheit");
                    }
                });
            }

            set_button = add_button (_("Set Language"));
            set_button.sensitive = false;
            set_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

            var set_system_button = add_button (_("Set System Language"));
            set_system_button.tooltip_text = _("Set language for login screen, guest account and new user accounts");

            var keyboard_button = add_start_button (_("Keyboard Settings…"));

            keyboard_button.clicked.connect (() => {
                try {
                    AppInfo.launch_default_for_uri ("settings://input/keyboard/layout", null);
                } catch (Error e) {
                    warning ("Failed to open keyboard settings: %s", e.message);
                }
            });

            unowned var installer = Installer.UbuntuInstaller.get_default ();

            missing_lang_infobar.response.connect (() => {
                missing_lang_infobar.revealed = false;
                installer.install_missing_languages ();
            });

            set_button.clicked.connect (() => {
                var locale = get_selected_locale ();
                debug ("Setting user language to '%s'", locale);
                lm.set_user_language (locale);

                compare ();

                var format = get_format ();
                debug ("Setting user format to '%s'", format);
                lm.set_user_format (format);

                restart_infobar.revealed = true;
            });

            set_system_button.clicked.connect (() => {
                if (!Utils.allowed_permission ()) {
                    return;
                }

                on_applied_to_system ();
            });

            installer.check_missing_finished.connect (on_check_missing_finished);
        }

        private void on_check_missing_finished (string[] missing) {
            missing_lang_infobar.revealed = missing.length > 0;
        }

        static construct {
            if (SettingsSchemaSource.get_default ().lookup ("org.gnome.GWeather", true) != null) {
                temperature_settings = new Settings ("org.gnome.GWeather");
            }
        }

        public string get_selected_locale () {
            var locale_object = (Locale) region_dropdown.selected_item;
            if (locale_object == null) {
                return "";
            }

            return locale_object.locale;
        }

        public string get_format () {
            var locale_object = (Locale) format_dropdown.selected_item;
            if (locale_object == null) {
                return "";
            }

            return locale_object.locale;
        }

        private void on_format_changed () {
            var format = get_format ();

            if (format != "") {
                preview.reload_languages (format);
            }
        }

        private void compare () {
            if (set_button != null) {
                if (lm.get_user_language () == get_selected_locale () && lm.get_user_format () == get_format ()) {
                    restart_infobar.revealed = false;
                    set_button.sensitive = false;
                } else {
                    set_button.sensitive = true;
                }
            }
        }

        public async void reload_locales (string language, Gee.HashSet<string> locales) {
            this.language = language;
            bool user_locale_found = false;

            locale_list.remove_all ();

            var default_regions = yield Utils.get_default_regions ();
            var user_locale = lm.get_user_language ();

            foreach (var locale in locales) {
                string code;
                if (!Gnome.Languages.parse_locale (locale, null, out code, null, null)) {
                    continue;
                }

                var region_string = Utils.translate_region (language, code, language);

                var locale_object = new Locale (region_string, locale);

                var position = locale_list.insert_sorted (locale_object, locale_sort_func);

                if (user_locale_found) {
                    continue;
                }

                if (user_locale == locale) {
                    region_dropdown.selected = position;
                    user_locale_found = true;
                } else if (default_regions.has_key (language) && locale.has_prefix (default_regions[language])) {
                    region_dropdown.selected = position;
                }
            }

            region_dropdown.sensitive = locale_list.n_items > 1;

            compare ();
        }

        private int locale_sort_func (Object a, Object b) {
            return ((Locale) a).name.collate (((Locale) b).name);
        }

        public void reload_formats (Gee.ArrayList<string>? locales) {
            format_list.remove_all ();
            var user_format = lm.get_user_format ();

            foreach (var locale in locales) {
                string country = Gnome.Languages.get_country_from_locale (locale, null);

                if (country != null) {
                    var locale_object = new Locale (country, locale);
                    var position = format_list.insert_sorted (locale_object, locale_sort_func);

                    if (locale == user_format) {
                        format_dropdown.selected = position;
                    }
                }
            }

            format_dropdown.sensitive = format_list.n_items > 1;

            compare ();
        }

        public void reload_labels (string language) {
            title = Utils.translate (language, null);
        }

        private void on_applied_to_system () {
            var selected_locale = get_selected_locale ();
            var selected_format = get_format ();
            debug ("Setting system language to '%s' and format to '%s'", selected_locale, selected_format);
            lm.apply_to_system (selected_locale, selected_format);

            restart_infobar.revealed = true;
        }

        private class Locale : Object {
            public string name { get; construct; }
            public string locale { get; construct; }

            public Locale (string name, string locale) {
                Object (name: name, locale: locale);
            }
        }
    }
}
