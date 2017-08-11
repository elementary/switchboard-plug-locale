/* Copyright 2015-2017 elementary LLC. (https://elementary.io)
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
    public class LanguageListBox : Gtk.ListBox {
        private Gee.HashMap <string, LanguageRow> languages;
        private LocaleManager lm;

        private Gtk.Label installed_languages_label;

        public signal void settings_changed ();

        public LanguageListBox () {
            languages = new Gee.HashMap <string, LanguageRow> ();
            lm = LocaleManager.get_default ();
            row_selected.connect (on_row_selected);

            installed_languages_label = new Gtk.Label (_("Installed Languages"));
            installed_languages_label.halign = Gtk.Align.START;
            installed_languages_label.get_style_context ().add_class ("h4");

            set_header_func (update_headers);
        }

        public void reload_languages (string[] langs) {
            //clear hashmap and this listbox
            languages.clear ();
            this.foreach ((item) => {
                this.remove (item);
            });

            foreach (var lang in langs) {
                add_language (lang);
            }

            foreach (Gtk.Widget row in get_children ()) {
                if (((LanguageRow)row).current) {
                    select_row ((LanguageRow)row);
                }
            }

            show_all ();
        }

        private void add_language (string language) {
            var code = language.slice (0, 2);
            if (!languages.has_key (code) && (language.length == 2 || language.length == 5)) {
                var language_string = Utils.translate (code, null);

                LanguageRow label;
                if (lm.get_user_language ().slice (0, 2) == code) {
                    label = new LanguageRow (code, language_string, true);
                } else {
                    label = new LanguageRow (code, language_string);
                }

                languages.set (code, label);
                add (label);
            }
        }

        private void on_row_selected (Gtk.ListBoxRow? row) {
            if (row != null) {
                settings_changed ();
            }
        }

        public void set_current (string code) {
            foreach (Gtk.Widget row in get_children ()) {
                if (((LanguageRow)row).code == code) {
                    ((LanguageRow)row).current = true;
                } else {
                    ((LanguageRow)row).current = false;
                }
            }
        }

        private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
            if (row == get_row_at_index (0)) {
                row.set_header (installed_languages_label);
            }
        }

        public string? get_selected_language_code () {
            var selected_row = get_selected_row () as LanguageRow;
            if (selected_row != null) {
                return selected_row.code;
            } else {
                return null;
            }
        }

        private class LanguageRow : Gtk.ListBoxRow {
            public string code { get; construct; }
            public string text { get; construct; }

            private bool _current;
            public bool current {
                get {
                    return _current;
                }
                set {
                    if (value) {
                        image.icon_name = "selection-checked";
                        image.tooltip_text = _("Currently active language");
                    } else {
                        image.tooltip_text = "";
                        image.clear ();
                    }
                    _current = value;
                }
            }

            private Gtk.Image image;

            public LanguageRow (string code, string text, bool current = false) {
                Object (
                    code: code,
                    current: current,
                    text: text
                );
            }

            construct {
                image = new Gtk.Image ();
                image.hexpand = true;
                image.halign = Gtk.Align.END;
                image.icon_size = Gtk.IconSize.BUTTON;

                var label = new Gtk.Label (text);
                label.halign = Gtk.Align.START;

                var grid = new Gtk.Grid ();
                grid.column_spacing = 6;
                grid.margin = 6;
                grid.add (label);
                grid.add (image);

                add (grid);
                show_all ();
            }
        }
    }
}
