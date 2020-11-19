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
    public class LocaleSetting : Granite.SimpleSettingsPage {
        private Gtk.Button set_button;
        private Gtk.ComboBox format_combobox;
        private Gtk.ComboBox region_combobox;
        private Gtk.ComboBox first_day_combobox;
        private Gtk.ListStore format_store;
        private Gtk.ListStore region_store;
        private Gtk.ListStore first_day_store;

        private LocaleManager lm;
        private Preview preview;
        private string language;
        private string selected_language = "";
        private string selected_format = "";
        private int selected_first_day;
        private bool has_region;
        private EndLabel region_endlabel;
        private EndLabel first_day_endlabel;

        private static GLib.Settings? temperature_settings = null;

        public signal void settings_changed ();

        public LocaleSetting () {
            Object (icon_name: "preferences-desktop-locale");
        }

        construct {
            lm = LocaleManager.get_default ();

            var region_label = new Gtk.Label ("");
            region_label.halign = Gtk.Align.START;

            Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
            region_store = new Gtk.ListStore (2, typeof (string), typeof (string));

            region_combobox = new Gtk.ComboBox.with_model (region_store);
            region_combobox.height_request = 27;
            region_combobox.pack_start (renderer, true);
            region_combobox.add_attribute (renderer, "text", 0);
            region_combobox.changed.connect (compare);

            format_store = new Gtk.ListStore (2, typeof (string), typeof (string));

            format_combobox = new Gtk.ComboBox.with_model (format_store);
            format_combobox.pack_start (renderer, true);
            format_combobox.add_attribute (renderer, "text", 0);
            format_combobox.changed.connect (on_format_changed);
            format_combobox.changed.connect (compare);
            format_combobox.active = 0;

            first_day_store = new Gtk.ListStore (2, typeof (int), typeof (string));

            first_day_combobox = new Gtk.ComboBox.with_model (first_day_store);
            first_day_combobox.pack_start (renderer, true);
            first_day_combobox.add_attribute (renderer, "text", 0);
            first_day_combobox.active = lm.get_user_first_day ();
            first_day_combobox.changed.connect (() => {
                lm.set_user_first_day (first_day_combobox.active);
                compare ();
            });

            preview = new Preview ();
            preview.margin_bottom = 12;
            preview.margin_top = 12;

            region_endlabel = new EndLabel (_("Region: "));
            first_day_endlabel = new EndLabel (_("First Day Of Week: "));

            content_area.halign = Gtk.Align.CENTER;
            content_area.attach (region_endlabel, 0, 2, 1, 1);
            content_area.attach (region_combobox, 1, 2, 1, 1);
            content_area.attach (new EndLabel (_("Formats: ")), 0, 3, 1, 1);
            content_area.attach (format_combobox, 1, 3, 1, 1);
            content_area.attach (first_day_endlabel, 0, 4, 1, 1);
            content_area.attach (first_day_combobox, 1, 4, 1, 1);
            content_area.attach (preview, 0, 6, 2, 1);

            if (temperature_settings != null) {
                var temperature = new Granite.Widgets.ModeButton ();
                temperature.append_text (_("Celsius"));
                temperature.append_text (_("Fahrenheit"));

                content_area.attach (new EndLabel (_("Temperature:")), 0, 5, 1, 1);
                content_area.attach (temperature, 1, 5, 1, 1);

                var temp_setting = temperature_settings.get_string ("temperature-unit");

                if (temp_setting == "centigrade") {
                    temperature.selected = 0;
                } else if (temp_setting == "fahrenheit") {
                    temperature.selected = 1;
                }

                temperature.mode_changed.connect (() => {
                    if (temperature.selected == 0) {
                        temperature_settings.set_string ("temperature-unit", "centigrade");
                    } else {
                        temperature_settings.set_string ("temperature-unit", "fahrenheit");
                    }
                });

            }

            set_button = new Gtk.Button.with_label (_("Set Language"));
            set_button.sensitive = false;
            set_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

            var set_system_button = new Gtk.Button.with_label (_("Set System Language"));
            set_system_button.tooltip_text = _("Set language for login screen, guest account and new user accounts");

            var keyboard_button = new Gtk.Button.with_label (_("Keyboard Settings…"));

            action_area.add (keyboard_button);
            action_area.add (set_system_button);
            action_area.add (set_button);
            action_area.set_child_secondary (keyboard_button, true);

            show_all ();

            keyboard_button.clicked.connect (() => {
                try {
                    AppInfo.launch_default_for_uri ("settings://input/keyboard/layout", null);
                } catch (Error e) {
                    warning ("Failed to open keyboard settings: %s", e.message);
                }
            });

            set_button.clicked.connect (() => {
                if (!has_region) {
                    debug ("Setting user language to '%s'", language);
                    lm.set_user_language (language);
                    selected_language = language;
                } else {
                    var region = get_region ();
                    debug ("Setting user language to '%s_%s'", language, region);
                    lm.set_user_language ("%s_%s".printf (language, region));
                    selected_language = "%s_%s".printf (language, region);
                }
                selected_format = get_format ();

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

        public string get_region () {
            Gtk.TreeIter iter;
            string region;

            if (!region_combobox.get_active_iter (out iter)) {
                return "";
            }

            region_store.get (iter, 1, out region);

            return region;
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
            if (set_button != null && selected_language != "" && selected_format != "") {
                var compare_language = language;
                if (has_region) {
                    compare_language = "%s_%s".printf (compare_language, get_region ());
                }

                if (compare_language == selected_language && selected_format == get_format ()) {
                    set_button.sensitive = false;
                } else {
                    set_button.sensitive = true;
                }
            }
        }

        public class EndLabel : Gtk.Label {
            public EndLabel (string label) {
                Object (
                    halign: Gtk.Align.END,
                    label: label
                );
            }
        }

        public async void reload_regions (string language, Gee.ArrayList<string> regions) {
            this.language = language;
            int selected_region = 0;

            region_store.clear ();

            int i = 0;
            has_region = false;
            foreach (var region in regions) {
                has_region = true;
                var region_string = Utils.translate_region (language, region, language);

                var iter = Gtk.TreeIter ();
                region_store.append (out iter);
                region_store.set (iter, 0, region_string, 1, region);

                if (lm.get_user_language ().length == 5 && lm.get_user_language ().slice (0, 2) == language
                    && lm.get_user_language ().slice (3, 5) == region) {
                        selected_region = i;
                }

                var default_regions = yield Utils.get_default_regions ();
                if (default_regions.has_key (language) && lm.get_user_language ().slice (0, 2) != language
                && default_regions.@get (language) == "%s_%s".printf (language, region)) {
                    selected_region = i;
                }

                i++;
            }

            region_combobox.active = selected_region;

            region_store.set_sort_column_id (0, Gtk.SortType.ASCENDING);

            if (i == 0) {
                region_endlabel.hide ();
                region_combobox.hide ();
            } else {
                region_endlabel.show ();
                region_combobox.show ();
            }

            if (selected_language == "" && has_region) {
                selected_language = "%s_%s".printf (language, get_region ());
            } else if (selected_language == "" && !has_region) {
                selected_language = language;
            }

            compare ();
        }

        public void reload_formats (Gee.ArrayList<string>? locales) {
            format_store.clear ();
            var user_format = lm.get_user_format ();
            int format_id = 0;

            int i = 0;
            foreach (var locale in locales) {
                string country = null;

                if (locale.length == 2) {
                    country = Gnome.Languages.get_country_from_code (locale, null);
                } else if (locale.length == 5) {
                    country = Gnome.Languages.get_country_from_locale (locale, null);
                }

                if (country != null) {
                    locale += ".UTF-8";
                    var iter = Gtk.TreeIter ();
                    format_store.append (out iter);
                    format_store.set (iter, 0, country, 1, locale);

                    if (locale == user_format) {
                        format_id = i;
                    }

                    i++;
                }
            }
            format_combobox.sensitive = i != 1; // set to unsensitive if only have one item
            format_combobox.active = format_id;

            format_store.set_sort_column_id (0, Gtk.SortType.ASCENDING);

            if (selected_format == "") {
                selected_format = get_format ();
            }

            compare ();
        }

        public void reload_first_day () {
            Gee.ArrayList<string>? first_days = new Gee.ArrayList<string> ();
            // As per real world data, First Day option in many countries boils down to these 4 options.
            first_days.add (_("Sunday"));
            first_days.add (_("Monday"));
            first_days.add (_("Friday"));
            first_days.add (_("Saturday"));
            first_day_store.clear ();
            var user_first_day = lm.get_user_first_day ();
            int first_day_id = 0;

            int i = 0;
            foreach (var first_day in first_days) {
                var iter = Gtk.TreeIter ();
                first_day_store.append (out iter);
                first_day_store.set (iter, 0, first_days.index_of (first_day), 1, first_day);

                if (first_days.index_of (first_day) == user_first_day) {
                    first_day_id = i;
                }

                i++;
            }
            first_day_combobox.sensitive = i != 1; // set to unsensitive if only have one item
            first_day_combobox.active = user_first_day;

            if (selected_first_day == 0) {
                selected_first_day = user_first_day;
            }

            compare ();
        }

        public void reload_labels (string language) {
            title = Utils.translate (language, null);
        }

        private void on_applied_to_system () {
            if (!has_region) {
                debug ("Setting system language to '%s' and format to '%s'", language, get_format ());
                lm.apply_to_system (language, get_format ());
            } else {
                debug ("Setting system language to '%s_%s' and format to '%s'", language, get_region (), get_format ());
                lm.apply_to_system ("%s_%s".printf (language, get_region ()), get_format ());
            }
            settings_changed ();
        }
    }
}
