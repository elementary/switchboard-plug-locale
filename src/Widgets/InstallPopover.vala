/* Copyright 2011-2017 elementary LLC. (https://elementary.io)
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

public class SwitchboardPlugLocale.Widgets.InstallPopover : Gtk.Popover {
    public signal void language_selected (string lang);

    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox list_box;

    construct {
        search_entry = new Gtk.SearchEntry ();
        search_entry.margin = 12;

        list_box = new Gtk.ListBox ();
        list_box.set_filter_func ((Gtk.ListBoxFilterFunc) filter_function);
        list_box.set_sort_func ((Gtk.ListBoxSortFunc) sort_function);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.height_request = 200;
        scrolled.width_request = 300;
        scrolled.add (list_box);

        var grid = new Gtk.Grid ();
        grid.margin_bottom = 3;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (search_entry);
        grid.add (scrolled);
        grid.show_all ();

        add (grid);

        load_languagelist ();

        search_entry.grab_focus ();

        list_box.row_activated.connect ((row) => {
            popdown ();
            language_selected (((LangRow) row).lang);
        });

        search_entry.activate.connect (() => {
            list_box.get_row_at_y (0).activate ();
        });

        search_entry.search_changed.connect (() => {
            list_box.invalidate_filter ();
        });
    }

    [CCode (instance_pos = -1)]
    private int sort_function (LangRow row1, LangRow row2) {
        return row1.lang.collate (row2.lang);
    }

    [CCode (instance_pos = -1)]
    private bool filter_function (LangRow row) {
        if (search_entry.text == "") {
            return true;
        }

        var search_term = search_entry.text.down ();
        var english_lang = Utils.translate (row.lang, "C").down ();
        var translated_lang = Utils.translate (row.lang, null).down ();

        if (search_term in english_lang || search_term in translated_lang) {
            return true;
        }

        return false;
    }

    private void load_languagelist () {
        var file = File.new_for_path (Path.build_path ("/", Constants.PKGDATADIR, "languagelist"));
        try {
            var dis = new DataInputStream (file.read ());
            string line;
            var langs = new GLib.List<string> ();
            while ((line = dis.read_line (null)) != null) {
                if (line.substring (0,1) != "#" && line != "") {
                    if (line == "ia") {
                        continue;
                    }

                    if (langs.find_custom (line, strcmp).length () == 0) {
                        var langrow = new LangRow (line);
                        list_box.add (langrow);
                        langs.append (line);
                    }
                }
            }

            list_box.show_all ();
        } catch (Error e) {
            critical (e.message);
        }
    }

    private class LangRow : Gtk.ListBoxRow {
        public string lang { get; construct; }

        public LangRow (string lang) {
            Object (lang: lang);
        }

        construct {
            var label = new Gtk.Label (Utils.translate (lang, null));
            label.margin = 6;
            label.margin_start = label.margin_end = 12;
            label.xalign = 0;

            add (label);
        }
    }
}
