/***
  Copyright (C) 2011-2012 Switchboard Locale Plug Developers
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.
  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.
  You should have received a copy of the GNU General Public License along
  with this program. If not, see
***/

namespace SwitchboardPlugLocale.Widgets {
    public class LocaleSetting : Gtk.Grid {
        private Gtk.Label       language_label;
        private Gtk.Label       region_label;

        private Gtk.ComboBox    format_combobox;
        private Gtk.ListStore   format_store;

        private Gtk.ComboBox    region_combobox;
        private Gtk.ListStore   region_store;

        private Gtk.Button      set_button;
        private Gtk.Button      set_system_button;

        private LocaleManager   lm;
        private Preview         preview;
        private string          language;
        private string          selected_language = "";
        private bool            has_region;

        private Gee.HashMap<string, string> default_regions;

        public signal void settings_changed ();

        public LocaleSetting () {
            this.row_homogeneous = false;
            this.margin = 20;
            this.row_spacing = 10;
            this.column_spacing = 10;
            this.halign = Gtk.Align.CENTER;

            lm = LocaleManager.get_default ();
            default_regions = Utils.get_default_regions ();

            language_label = new Gtk.Label ("");
            language_label.halign = Gtk.Align.START;

            region_label = new Gtk.Label ("");
            region_label.halign = Gtk.Align.START;

            Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
            region_store = new Gtk.ListStore (2, typeof (string), typeof (string));

            region_combobox = new Gtk.ComboBox.with_model (region_store);
            region_combobox.set_size_request (0, 27);
            region_combobox.pack_start (renderer, true);
            region_combobox.add_attribute (renderer, "text", 0);
            region_combobox.changed.connect (compare);

            format_store = new Gtk.ListStore (2, typeof (string), typeof (string));

            format_combobox = new Gtk.ComboBox.with_model (format_store);
            format_combobox.pack_start (renderer, true);
            format_combobox.add_attribute (renderer, "text", 0);
            format_combobox.changed.connect (on_format_changed);
            format_combobox.active = 0;

            preview = new Preview ();

            attach (create_end_label (_("Language: ")), 0, 0, 1, 1);
            attach (language_label,1, 0, 1, 1);
            attach (create_end_label (_("Region: ")), 0, 2, 1, 1);
            attach (region_combobox, 1, 2, 1, 1);
            attach (create_end_label (_("Formats: ")), 0, 3, 1, 1);
            attach (format_combobox, 1, 3, 1, 1);
            attach (preview, 0, 4, 2, 1);

            set_button = new Gtk.Button ();
            set_button.label = _("Set Language");
            set_button.halign = Gtk.Align.START;
            set_button.set_size_request (150, 25);
            set_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

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

                compare ();

                var format = get_format ();
                debug ("Setting user format to '%s'", format);
                lm.set_user_format (format);

                settings_changed ();
            });

            set_system_button = new Gtk.Button ();
            set_system_button.label = _("Set System Language");
            set_system_button.set_tooltip_text (
                _("Set language for login screen, guest account and new user accounts"));
            set_system_button.halign = Gtk.Align.START;
            set_system_button.set_size_request (150, 25);
            set_system_button.set_sensitive (false);

            set_system_button.clicked.connect (() => {
                if (Utils.get_permission ().allowed) {
                    on_applied_to_system ();
                }
            });

            Gtk.Box button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            button_box.pack_start (set_system_button);
            button_box.pack_start (set_button);
            attach (button_box, 0, 5, 2, 1);

            Utils.get_permission ().notify["allowed"].connect (() => {
                if (Utils.get_permission ().allowed)
                    set_system_button.set_sensitive (true);
                else
                    set_system_button.set_sensitive (false);
            });

            this.show_all ();
        }

        public string get_region () {
            Gtk.TreeIter iter;
            string region;

            if (!region_combobox.get_active_iter (out iter))
                return "";
            region_store.get (iter, 1, out region);

            return region;
        }

        public string get_format () {
            Gtk.TreeIter iter;
            string format;

            if (!format_combobox.get_active_iter (out iter))
                return "";
            format_store.get (iter, 1, out format);

            return format;
        }

        private void on_format_changed () {
            var format = get_format ();

            if (format != "")
                preview.reload_languages (format);
        }

        private void compare () {
            var compare_language = language;
            if (has_region)
                compare_language = "%s_%s".printf (compare_language, get_region ());

            if (compare_language == selected_language)
                    set_button.set_sensitive (false);
            else
                set_button.set_sensitive (true);
        }

        private Gtk.Label create_end_label (string text) {
            var label = new Gtk.Label (text);
            label.halign = Gtk.Align.END;
            return label;
        }

        public void reload_regions (string language, Gee.ArrayList<string> regions) {
            this.language = language;
            int selected_region = 0;

            region_store.clear ();

            int i = 0;
            has_region = false;
            foreach (var region in regions) {
                has_region = true;
                var region_string = Utils.translate_region (language, region);

                var iter = Gtk.TreeIter ();
                region_store.append (out iter);
                region_store.set (iter, 0, region_string, 1, region);

                if (default_regions.has_key (language)
                && default_regions.@get (language) == "%s_%s".printf (language, region))
                    selected_region = i;

                i++;
            }

            region_combobox.sensitive = (i != 1 && i != 0);
            region_combobox.active = selected_region;

            if (selected_language == "" && has_region)
                selected_language = "%s_%s".printf (language, get_region ());
            else if (selected_language == "" && !has_region)
                selected_language = language;
            compare ();
        }

        public void reload_formats (Gee.ArrayList<string>? locales) {
            format_store.clear ();
            var user_format = lm.get_user_format ();
            int selected_format = 0;

            int i = 0;
            foreach (var locale in locales) {
                string country = null;

                if (locale.length == 2)
                    country = Gnome.Languages.get_country_from_code (locale, null);
                else if (locale.length == 5)
                    country = Gnome.Languages.get_country_from_locale (locale, null);

                if (country != null) {
                    locale += ".UTF-8";
                    var iter = Gtk.TreeIter ();
                    format_store.append (out iter);
                    format_store.set (iter, 0, country, 1, locale);

                    if (locale == user_format)
                        selected_format = i;

                    i++;
                }
            }
            format_combobox.sensitive = i != 1; // set to unsensitive if only have one item
            format_combobox.active = selected_format;
        }

        public void reload_labels (string language) {
            /* this seems stupid, but Utils.translate needs to be called twice to work.
             * I have no clue why, but well - this is only a workaround */
            var language_string = Utils.translate (language, null);
            language_string = Utils.translate (language, null);

            language_label.set_label (language_string);
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
