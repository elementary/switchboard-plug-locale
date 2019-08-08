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

namespace SwitchboardPlugLocale.Widgets {
    public class InstallPopover : Gtk.Popover {
        private Gtk.TreeView languages_view;
        private Gtk.ListStore list_store;

        public signal void language_selected (string lang);

        construct {
            var search_entry = new Gtk.SearchEntry ();

            list_store = new Gtk.ListStore (3, typeof (string), typeof (string), typeof (string));
            list_store.set_default_sort_func ((model, a, b) => {
                Value value_a;
                model.get_value (a, 0, out value_a);
                Value value_b;
                model.get_value (b, 0, out value_b);
                return value_a.get_string ().collate (value_b.get_string ());
            });

            languages_view = new Gtk.TreeView.with_model (list_store);
            languages_view.headers_visible = false;
            languages_view.insert_column_with_attributes (-1, "", new Gtk.CellRendererText (), "text", 0);
            languages_view.activate_on_single_click = true;
            languages_view.row_activated.connect (row_activated);
            languages_view.set_search_entry (search_entry);
            languages_view.set_search_equal_func (treesearchfunc);

            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.shadow_type = Gtk.ShadowType.IN;
            scrolled.height_request = 145;
            scrolled.width_request = 200;
            scrolled.add (languages_view);

            var grid = new Gtk.Grid ();
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.add (search_entry);
            grid.add (scrolled);
            grid.show_all ();

            add (grid);

            load_languagelist ();
        }

        static bool treesearchfunc (Gtk.TreeModel model, int column, string key, Gtk.TreeIter iter) {
            Value value;
            model.get_value (iter, 0, out value);
            if (key.down () in value.get_string ().down ()) {
                return false;
            }

            model.get_value (iter, 1, out value);
            if (key.down () in value.get_string ().down ()) {
                return false;
            }

            return true;
        }

        void row_activated (Gtk.TreePath path, Gtk.TreeViewColumn column) {
            Gtk.TreeIter iter;
            list_store.get_iter (out iter, path);
            Value value;
            list_store.get_value (iter, 2, out value);
            language_selected (value.get_string ());
            hide ();
        }

        void load_languagelist () {
            var file = File.new_for_path (Path.build_path ("/", Constants.PKGDATADIR, "languagelist"));
            try {
                var dis = new DataInputStream (file.read ());
                string line;
                var langs = new GLib.List<string> ();
                while ((line = dis.read_line (null)) != null) {
                    if (line.substring(0,1) != "#" && line != "") {
                        if (line == "ia")
                            continue;

                        if (langs.find_custom (line, strcmp).length () == 0) {
                            Gtk.TreeIter iter;
                            list_store.append (out iter);
                            list_store.set (iter, 0, Utils.translate (line, null), 1, Utils.translate (line, "C"), 2, line);
                            langs.append (line);
                        }
                    }
                }
            } catch (Error e) {
                error ("%s", e.message);
            }
        }
    }
}
