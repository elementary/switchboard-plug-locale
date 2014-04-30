public enum UpdateType {
    LANGUAGE,
    FORMAT,
    INPUT;
}

public class LanguageEntry : BaseEntry {


    public Gtk.Button delete_button;
    
    

    public signal void set_region (string region);

    public signal void language_changed (UpdateType type, string locale);
    public signal void input_changed (string langcode, string region, bool added);
    public signal void deletion_requested (string region);

    // language selecetion
    public Gtk.RadioButton check_button;
    Gtk.Label region_label;
    Gtk.ComboBox country_combobox;

    // region selection
    public Gtk.RadioButton format_checkbutton;
    Gtk.ComboBox format_combobox;

    // input selection
    public Gtk.CheckButton input_checkbutton;
    Gtk.ComboBox input_combobox;
    Gtk.ListStore input_store;

    Gtk.Image delete_image;

    Gtk.ListStore list_store;

    bool update_lock = false;

    Gtk.TreeIter iter;

    Gee.HashMap<string, int> regionbox_map = new Gee.HashMap<string, int> ();
    Gee.HashMap<string, int> inputbox_map = new Gee.HashMap<string, int> ();

    public string langcode;
 
    public LanguageEntry (string _locale, LanguageList? list = null) {
        locale = _locale;
        langcode = locale.substring (0, 2);

        country = Gnome.Languages.get_country_from_locale (locale, null);
        region = Gnome.Languages.get_language_from_code (locale.substring (0, 2), null);

        input_store = new Gtk.ListStore (2, typeof (string), typeof (string));
        list_store = new Gtk.ListStore (2, typeof (string), typeof (string));

        Gtk.CellRendererText value_renderer = new Gtk.CellRendererText ();
        value_renderer.ellipsize = Pango.EllipsizeMode.END;
        value_renderer.max_width_chars = 25;

        reload_input ();

        /*
         * Language (translation)
         */

        check_button = new Gtk.RadioButton.from_widget (list.language_button);
        check_button.toggled.connect (on_language_activated);
        check_button.set_active (false);

        region_label = new Gtk.Label (region);
        region_label.halign = Gtk.Align.START;
        region_label.set_markup ("<b>%s</b>".printf(region_label.label));

        country_combobox = new Gtk.ComboBox.with_model (list_store);
        country_combobox.changed.connect (on_language_changed);
        country_combobox.width_request = 50;
        country_combobox.halign = Gtk.Align.START;
        country_combobox.pack_start (value_renderer, true);
        country_combobox.add_attribute (value_renderer, "text", 0);

        var country_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        country_box.halign = Gtk.Align.START;
        country_box.pack_start (check_button, false, false);
        country_box.pack_start (region_label, false, false);
        country_box.pack_start (country_combobox, true, false);

        /*
         * Regional format (date, currency, …)
         */

        format_checkbutton = new Gtk.RadioButton.from_widget (list.format_button);
        format_checkbutton.toggled.connect (on_format_activated);

        format_combobox = new Gtk.ComboBox.with_model (list_store);
        format_combobox.changed.connect (on_format_changed);
        format_combobox.pack_start (value_renderer, true);
        format_combobox.add_attribute (value_renderer, "text", 0);

        var format_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        format_box.pack_start (format_checkbutton, false, false);
        format_box.pack_start (format_combobox, true, true);

        /*
         * Input language (Keyboard layout)
         */

        input_checkbutton = new Gtk.CheckButton ();
        input_checkbutton.toggled.connect (() => {
            on_input_changed ();
            });

        input_combobox = new Gtk.ComboBox.with_model (input_store);
        input_combobox.changed.connect (on_input_changed);
        input_combobox.pack_start (value_renderer, true);
        input_combobox.add_attribute (value_renderer, "text", 0);

        var input_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        input_box.pack_start (input_checkbutton, false, false);
        input_box.pack_start (input_combobox, true, true);


        left_box.pack_start (country_box);

        right_box.pack_start (format_box);
        right_box.pack_end (input_box);

        delete_image = new Gtk.Image.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.MENU);

        delete_button = new Gtk.ToggleButton();
        delete_button.get_style_context ().remove_class ("button");
        delete_button.set_image (delete_image);
        delete_button.sensitive = true;
        delete_button.clicked.connect (() => {
            deletion_requested (locale);
        });

        settings_box.pack_start (delete_button);

        add_region (locale);
    }

    void reload_input () {
        var xkb = new Gnome.XkbInfo ();
        var input_sources = xkb.get_layouts_for_language (langcode);

        foreach (var input in input_sources) {
            string display_name;
            string short_name;
            string xkb_layout;
            string xkb_variant;

            xkb.get_layout_info (input, out display_name, out short_name, out xkb_layout, out xkb_variant);
            //message("%s - %s - %s - %s", display_name, short_name, xkb_layout, xkb_variant);
            
            if (xkb_layout == "us" && langcode != "en") {
                // skip english international
                continue;
            }

            var xkb_string = xkb_layout;
            if (xkb_variant != "")
                xkb_string += "+"+xkb_variant;
            
            input_store.append (out iter);
            input_store.set (iter, 0, display_name, 1, xkb_string);

            inputbox_map.@set (xkb_string, inputbox_map.size);
        }
    }

    public void set_display_region (string locale) {

        update_lock = true;

        if (regionbox_map.has_key (locale)) {
            message("must set region to %s", locale);
            country_combobox.active = regionbox_map.@get (locale);
            check_button.active = true;
        } else {
            warning ("%s has no region %s", langcode, locale);
        }

        update_lock = false;
        
    }

    public void set_display_format (string locale) {

        update_lock = true;

        format_combobox.active = regionbox_map.@get (locale);
        format_checkbutton.active = true;

        update_lock = false;

    }

    public void set_display_input (string input) {
        
        update_lock = true;

        if (inputbox_map.has_key (input)) {
            var number = inputbox_map.@get (input);
            warning ("Number for %s is %d", input, number);
            input_combobox.active = number;
            input_checkbutton.active = true;

        }
        
        update_lock = false;
        
    }

    void on_language_activated () {
        
        if (update_lock) 
            return;

        Value lang;

        country_combobox.get_active_iter (out iter);

        list_store.get_value (iter, 1, out lang);

        language_changed (UpdateType.LANGUAGE, lang.get_string ());

    }

    void on_format_activated () {

        if (update_lock) 
            return;

        Value format;

        format_combobox.get_active_iter (out iter);
        list_store.get_value (iter, 1, out format);

        language_changed (UpdateType.FORMAT, format.get_string ());

    }

    void on_input_activated (bool? changed = false) {
        if (update_lock) 
            return;

        Value xkb_string;

        input_combobox.get_active_iter (out iter);
        input_store.get_value (iter, 1, out xkb_string);

        message ("Input %s %s", xkb_string.get_string (), changed ? "added" : "removed");

        input_changed (langcode, xkb_string.get_string (), changed);

    }

    void on_language_changed () {
        if (!check_button.active) {
            return;
        }

        on_language_activated ();

    }

    void on_format_changed () {
        if (!format_checkbutton.active) {

            return;
        }

        on_format_activated ();
    }

    void on_input_changed () {
        if (!input_checkbutton.active) {
            on_input_activated (false);
            return;
        }

        on_input_activated (true);
    }


    public void add_region (string locale) {
        var country = Gnome.Languages.get_country_from_locale (locale, null);
        //var region = Gnome.Languages.get_language_from_code (locale.substring (0, 2), null);

        

        if (country != null) {

            list_store.append (out iter);
            regionbox_map.@set (locale, regionbox_map.size);
            list_store.set (iter, 0, country, 1, locale);
        }
        

        country_combobox.active = 0;
        format_combobox.active = 0;
        input_combobox.active = 0;
    }

    public void add_format (string locale) {

    }

    public void hide_delete () {

        delete_image.set_opacity (0);

    }

    public void show_delete () {

        delete_image.set_opacity (1);
    }
}