public class InstallPopover : Gtk.Popover {

    Gtk.Box box;
    Gtk.SearchEntry search_entry;
    Gtk.ListBox languages_box;

    int visible_count = 0;
    string search_string = " ";

    public UbuntuInstaller li;

    public signal void language_selected (string lang);
    
    public InstallPopover (Gtk.Widget relative_to) {
        Object (relative_to: relative_to);
        set_position(Gtk.PositionType.BOTTOM);
        

        box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        box.margin = 5;

        search_entry = new Gtk.SearchEntry ();
        search_entry.search_changed.connect (on_search);
        box.pack_start (search_entry);

        languages_box = new Gtk.ListBox ();
        languages_box.set_activate_on_single_click(true);
        languages_box.set_selection_mode (Gtk.SelectionMode.NONE);
        languages_box.get_style_context ().add_class ("background");
        languages_box.set_filter_func(filter_func_text);
        languages_box.set_header_func (header_func);
        languages_box.row_activated.connect (row_activated);

        box.pack_start (languages_box);

        add (box);



        load_languagelist();
        on_search ();
    }

    void on_search () {
        visible_count = 0;
        search_string = search_entry.text;
        languages_box.set_filter_func(filter_func_text);
    
    }

    void row_activated (Gtk.ListBoxRow row) {
        var language_row = row as LanguageRow;

        //li.install (language_row.locale);
        language_selected (language_row.locale);
        hide ();
    }

    bool filter_func_text (Gtk.ListBoxRow row) {
        if (visible_count >= 5) {
            return false;
        }

        var compile_flags = RegexCompileFlags.CASELESS;
    

        try {
            var regex = new Regex (search_string, compile_flags);
            var locale = row as LanguageRow;
            var hit = regex.match (locale.lang);
            if (hit) {
                visible_count++;
                return true;
            }
            return false;
        } catch (Error e) {
            critical ("Error build filter: %s", e.message);
            return true;
        }

    }

    void load_languagelist () {
        var list_path = Constants.PKGDATADIR+"/languagelist";
        message ("Path: %s", list_path);
        var file = File.new_for_path (list_path);

        try {
        // Open file for reading and wrap returned FileInputStream into a
        // DataInputStream, so we can read line by line
        var dis = new DataInputStream (file.read ());
        string line;
        // Read lines until end of file (null) is reached
        while ((line = dis.read_line (null)) != null) {

            if (line.substring(0,1) != "#") {
                var values = line.split (";");
                languages_box.add (new LanguageRow (values[0], values[2]));
                //stdout.printf ("%s\n", values[0]);
            }
            
        }
        } catch (Error e) {
            error ("%s", e.message);
        }
    }

    void header_func (Gtk.ListBoxRow? row, Gtk.ListBoxRow? before) {
        if (before != null) {
            row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        }
    }
}
public class LanguageRow : Gtk.ListBoxRow {

    public string lang;
    public string locale;

    Gtk.Label language_label;

    public LanguageRow (string language, string _locale) {
        lang = language;
        locale = _locale;
        get_style_context ().add_class ("background");

        language_label = new Gtk.Label (language);
        language_label.halign = Gtk.Align.START;
        language_label.margin = 5;
        language_label.set_markup ("<b>%s</b>".printf(language));

        add (language_label);
    }
}