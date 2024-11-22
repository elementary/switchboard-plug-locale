/* Copyright 2015-2019 elementary, Inc. (https://elementary.io)
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

public class SwitchboardPlugLocale.Widgets.LanguageListBox : Gtk.Box {
    public Gtk.ListBox listbox { get; private set; }

    private Gee.HashMap <string, LanguageRow> languages;
    private LocaleManager lm;
    private Granite.HeaderLabel installed_languages_label;

    construct {
        languages = new Gee.HashMap <string, LanguageRow> ();
        lm = LocaleManager.get_default ();

        listbox = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true
        };
        listbox.set_header_func (update_headers);

        installed_languages_label = new Granite.HeaderLabel (_("Installed Languages")) {
            mnemonic_widget = listbox
        };

        append (listbox);
    }

    public void reload_languages (Gee.ArrayList<string> langs) {
        //clear hashmap and this listbox
        languages.clear ();

        while (listbox.get_first_child () != null) {
            listbox.remove (listbox.get_first_child ());
        }

        langs.sort ((a, b) => {
            return a.collate (b);
        });

        foreach (var locale in langs) {
            string code;
            if (!Gnome.Languages.parse_locale (locale, out code, null, null, null)) {
                continue;
            }

            add_language (code, locale);
        }

        var row = listbox.get_first_child ();
        while (row != null) {
            if (row is LanguageRow && ((LanguageRow)row).current) {
                listbox.select_row ((LanguageRow)row);
            }

            row = row.get_next_sibling ();
        }
    }

    private void add_language (string code, string locale) {
        if (!languages.has_key (code)) {
            var language_string = Utils.translate (code, locale);

            languages[code] = new LanguageRow (code, language_string);
            listbox.append (languages[code]);

            if (lm.get_user_language ().slice (0, 2) == code) {
                languages[code].current = true;
            }
        }
    }

    public void set_current (string code) {
        var row = get_first_child ();
        while (row != null) {
            if (((LanguageRow)row).code == code) {
                ((LanguageRow)row).current = true;
            } else {
                ((LanguageRow)row).current = false;
            }

            row = row.get_next_sibling ();
        }
    }

    private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
        if (row == listbox.get_row_at_index (0)) {
            row.set_header (installed_languages_label);
        }
    }

    public string? get_selected_language_code () {
        var selected_row = listbox.get_selected_row () as LanguageRow;
        if (selected_row != null) {
            return selected_row.code;
        } else {
            return null;
        }
    }

    public string? get_selected_language_name () {
        var selected_row = listbox.get_selected_row () as LanguageRow;
        if (selected_row != null) {
            return selected_row.text;
        } else {
            return null;
        }
    }

    private class LanguageRow : Gtk.ListBoxRow {
        public string code { get; construct; }
        public string text { get; construct; }

        private Gtk.Box box;
        private Gtk.CheckButton? check_button;
        // group_check_button is used for forcing radio button style
        private static Gtk.CheckButton group_check_button;

        public bool current {
            get {
                return check_button != null;
            }
            set {
                if (value) {
                    check_button = new Gtk.CheckButton () {
                        active = true,
                        group = group_check_button,
                        focusable = false,
                        tooltip_text = _("Currently active language")
                    };
                    box.append (check_button);
                } else {
                    box.remove (check_button);
                    check_button = null;
                }
            }
        }

        static construct {
            group_check_button = new Gtk.CheckButton ();
        }

        public LanguageRow (string code, string text) {
            Object (code: code, text: text);
        }

        construct {
            var label = new Gtk.Label (text) {
                halign = Gtk.Align.START,
                hexpand = true
            };

            box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            box.append (label);

            child = box;
        }
    }
}
