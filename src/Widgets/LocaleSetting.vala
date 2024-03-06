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
        private Gtk.ComboBox format_combobox;
        private Gtk.DropDown region_dropdown;
        private Gtk.ListStore format_store;
        private GLib.ListStore locale_list;

        private LocaleManager lm;
        private Preview preview;
        private string language;
        private Gtk.Label region_endlabel;

        private static GLib.Settings? temperature_settings = null;

        public signal void settings_changed ();

        public LocaleSetting () {
            Object (icon: new ThemedIcon ("preferences-desktop-locale"));
        }

        construct {
            lm = LocaleManager.get_default ();

            var region_label = new Gtk.Label ("");
            region_label.halign = Gtk.Align.START;

            Gtk.CellRendererText renderer = new Gtk.CellRendererText ();

            locale_list = new GLib.ListStore (typeof (Locale));

            var region_factory = new Gtk.SignalListItemFactory ();
            region_factory.setup.connect (region_setup_factory);
            region_factory.bind.connect (region_bind_factory);

            region_dropdown = new Gtk.DropDown (locale_list, null) {
                factory = region_factory
            };
            region_dropdown.notify["selected"].connect (compare);

            format_store = new Gtk.ListStore (2, typeof (string), typeof (string));

            format_combobox = new Gtk.ComboBox.with_model (format_store);
            format_combobox.pack_start (renderer, true);
            format_combobox.add_attribute (renderer, "text", 0);
            format_combobox.changed.connect (on_format_changed);
            format_combobox.changed.connect (compare);
            format_combobox.active = 0;

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

            var content_area = new Gtk.Grid () {
                column_spacing = 6,
                row_spacing = 12
            };
            content_area.attach (region_endlabel, 0, 2);
            content_area.attach (region_dropdown, 1, 2, 2);
            content_area.attach (formats_label, 0, 3);
            content_area.attach (format_combobox, 1, 3, 2);
            content_area.attach (preview, 0, 5, 3);

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
            set_button.get_style_context ().add_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

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

            set_button.clicked.connect (() => {
                var locale = get_selected_locale ();
                debug ("Setting user language to '%s'", locale);
                lm.set_user_language (locale);

                compare ();

                var format = get_format ();
                debug ("Setting user format to '%s'", format);
                lm.set_user_format (format);

                settings_changed ();
            });

            set_system_button.clicked.connect (() => {
                if (!Utils.allowed_permission ()) {
                    return;
                }

                on_applied_to_system ();
            });
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
            Gtk.TreeIter iter;
            string format;

            if (!format_combobox.get_active_iter (out iter)) {
                return "";
            }

            format_store.get (iter, 1, out format);

            return format;
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
                    set_button.sensitive = false;
                } else {
                    set_button.sensitive = true;
                }
            }
        }

        public async void reload_locales (string language, Gee.HashSet<string> locales) {
            this.language = language;
            uint selected_locale_id = 0;
            bool user_locale_found = false;
            int locales_added = 0;

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

                locale_list.insert_sorted (locale_object, locale_sort_func);

                if (user_locale == locale) {
                    locale_list.find (locale_object, out selected_locale_id);
                    user_locale_found = true;
                }

                if (!user_locale_found && default_regions.has_key (language)) {
                    if (locale.has_prefix (default_regions[language])) {
                        locale_list.find (locale_object, out selected_locale_id);
                    }
                }

                locales_added++;
            }

            region_dropdown.sensitive = locales_added > 1;
            region_dropdown.selected = selected_locale_id + 1;

            compare ();
        }

        private int locale_sort_func (Object a, Object b) {
            return ((Locale) a).name.collate (((Locale) b).name);
        }

        public void reload_formats (Gee.ArrayList<string>? locales) {
            format_store.clear ();
            var user_format = lm.get_user_format ();

            int i = 0;
            string? active_id = null;
            foreach (var locale in locales) {
                string country = Gnome.Languages.get_country_from_locale (locale, null);

                if (country != null) {
                    var iter = Gtk.TreeIter ();
                    format_store.append (out iter);
                    format_store.set (iter, 0, country, 1, locale);

                    if (locale == user_format) {
                        active_id = locale;
                    }

                    i++;
                }
            }

            format_combobox.id_column = 1;
            format_combobox.sensitive = i != 1; // set to unsensitive if only have one item
            if (active_id != null) {
                format_combobox.active_id = active_id;
            } else {
                format_combobox.active = 0;
            }

            format_store.set_sort_column_id (0, Gtk.SortType.ASCENDING);

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

            settings_changed ();
        }

        private void region_setup_factory (Object object) {
            var title = new Gtk.Label ("") {
                xalign = 0
            };

            var list_item = (Gtk.ListItem) object;
            list_item.child = title;
        }

        private void region_bind_factory (Object object) {
            var list_item = object as Gtk.ListItem;

            var locale = (Locale) list_item.get_item ();

            var title = (Gtk.Label) list_item.child;
            title.label = locale.name;
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
