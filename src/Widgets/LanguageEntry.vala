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

public enum UpdateType {
    LANGUAGE,
    FORMAT;
}

public class LanguageEntry : BaseEntry {

    public Gtk.Button delete_button;

    public signal void set_region (string region);

    public signal void language_changed (UpdateType type, string locale);
    public signal void deletion_requested (string region);

    // language selecetion
    public Gtk.RadioButton check_button;
    Gtk.Label region_label;
    Gtk.ComboBox country_combobox;

    // region selection
    public Gtk.RadioButton format_checkbutton;
    Gtk.Label region_second_label;
    Gtk.ComboBox format_combobox;
    Gtk.ListStore format_store;

    Gtk.Image delete_image;

    Gtk.ListStore list_store;

    bool update_lock = false;

    Gtk.TreeIter iter;

    Gee.HashMap<string, int> regionbox_map = new Gee.HashMap<string, int> ();
    Gee.HashMap<string, int> formatbox_map = new Gee.HashMap<string, int> ();

    public string langcode;

    private const string STYLE = """

        GtkListBoxRow.list-row {
            background-image: none;
            background-color: #fff;
            border-radius: 5px;
            border: 1px solid #ccc;
        }

    """;

    public LanguageEntry (string _locale, LanguageList? list = null) {

        var css_provider = new Gtk.CssProvider ();
        try {
            css_provider.load_from_data (STYLE, STYLE.length);
        } catch (Error e) {
            warning ("loading css: %s", e.message);
        }          
        get_style_context ().add_provider (css_provider, -1);
        margin_bottom = 5;

        locale = _locale;
        langcode = locale.substring (0, 2);

        country = Gnome.Languages.get_country_from_locale (locale, null);
        region = Gnome.Languages.get_language_from_code (langcode, null);

        format_store = new Gtk.ListStore (2, typeof (string), typeof (string));
        list_store = new Gtk.ListStore (2, typeof (string), typeof (string));

        Gtk.CellRendererText value_renderer = new Gtk.CellRendererText ();
        value_renderer.ellipsize = Pango.EllipsizeMode.END;
        value_renderer.max_width_chars = 25;

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
        country_combobox.pack_start (value_renderer, true);
        country_combobox.add_attribute (value_renderer, "text", 0);

        left_grid.attach (check_button, 0, 0, 1, 1);
        left_grid.attach (region_label, 1, 0, 1, 1);
        left_grid.attach (country_combobox, 2, 0, 1, 1);

        /*
         * Regional format (date, currency, …)
         */

        region_second_label = new Gtk.Label (region);
        region_second_label.halign = Gtk.Align.START;
        region_second_label.set_markup ("<b>%s</b>".printf(region_second_label.label));

        format_checkbutton = new Gtk.RadioButton.from_widget (list.format_button);
        format_checkbutton.toggled.connect (on_format_activated);

        format_combobox = new Gtk.ComboBox.with_model (format_store);
        format_combobox.changed.connect (on_format_changed);
        format_combobox.pack_start (value_renderer, true);
        format_combobox.add_attribute (value_renderer, "text", 0);

        right_grid.attach (format_checkbutton, 0, 0, 1, 1);
        right_grid.attach (region_second_label, 1, 0, 1, 1);
        right_grid.attach (format_combobox, 2, 0, 1, 1);

        delete_button = new Gtk.ToggleButton ();
        delete_button.image = new Gtk.Image.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON);
        delete_button.tooltip_text = _("Remove");
        delete_button.clicked.connect (() => {
            deletion_requested (locale);
        });

        settings_grid.pack_start (delete_button);
        
        add_language (locale);

        show_all ();
    }

    public void set_display_region (string locale) {

        update_lock = true;

        if (regionbox_map.has_key (locale)) {
            country_combobox.active = regionbox_map.@get (locale);
            check_button.active = true;
        }

        update_lock = false;
        
    }

    public void set_display_format (string locale) {

        update_lock = true;

        format_combobox.active = formatbox_map.@get (locale);
        format_checkbutton.active = true;

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
        format_store.get_value (iter, 1, out format);
        message ("%s", format.get_string ());
        language_changed (UpdateType.FORMAT, format.get_string ());

    }

    void on_language_changed () {
        if (!check_button.active)
            return;

        on_language_activated ();

    }

    void on_format_changed () {
        if (!format_checkbutton.active)
            return;

        on_format_activated ();
    }

    public void add_language (string locale) {

        string language = "";
        string country = "";

        if (locale.length == 2)  {// only lancode
            language = Gnome.Languages.get_language_from_code (locale, null);
            country = Gnome.Languages.get_country_from_code (locale, null);
        } else if (locale.length == 5) {// full locale
            language = Gnome.Languages.get_language_from_locale (locale, null);
            country = Gnome.Languages.get_country_from_locale (locale, null);
        }

        if (country == null)
            country = language;


        list_store.append (out iter);
        regionbox_map.@set (locale, regionbox_map.size);
        list_store.set (iter, 0, country, 1, locale);

        
        country_combobox.active = 0;
    }

    public void add_locale (string locale) {
        var country = Gnome.Languages.get_country_from_locale (locale, null);

        var country_short = country.replace ("(%s)".printf (region), "");
        if (country != null) {
            format_store.append (out iter);
            formatbox_map.@set (locale, formatbox_map.size);
            format_store.set (iter, 0, country_short, 1, locale);

            format_combobox.show ();
            format_checkbutton.show ();
        }

        format_combobox.active = 0;
    }

    public void hide_delete () {

        delete_image.set_opacity (0);

    }

    public void show_delete () {

        delete_image.set_opacity (1);
    }
}
