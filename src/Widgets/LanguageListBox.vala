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
                if (((LanguageRow)row).current)
                    select_row ((LanguageRow)row);
            }

            show_all ();
        }

        private void add_language (string language) {
            var code = language.slice (0, 2);
            if (!languages.has_key (code) && (language.length == 2 || language.length == 5)) {
                var language_string = Utils.translate (code, null);

                LanguageRow label;
                if (lm.get_user_language ().slice (0, 2) == code)
                    label = new LanguageRow (code, language_string, true);
                else
                    label = new LanguageRow (code, language_string);

                languages.set (code, label);
                add (label);
            }
        }

        private void on_row_selected (Gtk.ListBoxRow? row) {
            if (row != null)
                settings_changed ();
        }

        public void set_current (string code) {
            foreach (Gtk.Widget row in get_children ()) {
                if (((LanguageRow)row).code == code)
                    ((LanguageRow)row).set_current (true);
                else
                    ((LanguageRow)row).set_current (false);
            }
        }

        private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
            if (row == get_row_at_index (0))
                row.set_header (installed_languages_label);
        }

        public string? get_selected_language_code () {
            var selected_row = get_selected_row () as LanguageRow;
            if (selected_row != null)
                return selected_row.code;
            else
                return null;
        }

        private class LanguageRow : Gtk.ListBoxRow {
            public string       code;
            public bool         current;
            private Gtk.Box     box;
            private Gtk.Label   label;
            private Gtk.Image   image;

            public LanguageRow (string code, string text, bool current = false) {
                this.code = code;
                box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                this.current = current;
                image = new Gtk.Image ();
                image.halign = Gtk.Align.END;
                image.margin_right = 6;

                if (current) {
                    image.set_from_icon_name ("selection-checked", Gtk.IconSize.BUTTON);
                    image.set_tooltip_text (_("Currently active language"));
                }

                box.pack_end (image);
                label = new Gtk.Label (text);
                label.halign = Gtk.Align.START;
                label.margin = 10;
                box.pack_start (label);
                this.add (box);
                show_all ();
            }

            public void set_current (bool new_current) {
                this.current = new_current;
                if (current)
                    image.set_from_icon_name ("selection-checked", Gtk.IconSize.BUTTON);
                else {
                    image.set_tooltip_text ("");
                    image.clear ();
                }
            }
        }
    }
}
