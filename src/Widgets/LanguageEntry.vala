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
    public signal void set_region (string region);

    public signal void language_changed (UpdateType type, string locale);
    public signal void deletion_requested (string region);

    // language selecetion
    public Gtk.RadioButton region_checkbutton;
    Gtk.Label region_label;
    Gtk.ComboBoxText region_combobox;

    // region selection
    public Gtk.RadioButton format_checkbutton;
    Gtk.Label format_label;
    Gtk.ComboBoxText format_combobox;
    Gtk.Button delete_button;

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

        /*
         * Language (translation)
         */

        region_checkbutton = new Gtk.RadioButton.from_widget (list.language_button);
        region_checkbutton.toggled.connect (on_language_activated);
        region_checkbutton.set_active (false);

        region_label = new Gtk.Label ("<b>%s</b>".printf(region));
        region_label.halign = Gtk.Align.START;
        region_label.use_markup = true;

        region_combobox = new Gtk.ComboBoxText ();
        region_combobox.changed.connect (on_language_changed);
        region_combobox.width_request = 150;

        left_grid.attach (region_checkbutton, 0, 0, 1, 1);
        left_grid.attach (region_label, 1, 0, 1, 1);
        left_grid.attach (region_combobox, 2, 0, 1, 1);

        /*
         * Regional format (date, currency, …)
         */

        format_label = new Gtk.Label ("<b>%s</b>".printf(region));
        format_label.halign = Gtk.Align.START;
        format_label.use_markup = true;

        format_checkbutton = new Gtk.RadioButton.from_widget (list.format_button);
        format_checkbutton.toggled.connect (on_format_activated);

        format_combobox = new Gtk.ComboBoxText ();
        format_combobox.changed.connect (on_format_changed);
        format_combobox.width_request = 150;

        right_grid.attach (format_checkbutton, 0, 0, 1, 1);
        right_grid.attach (format_label, 1, 0, 1, 1);
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

    bool update_region_lock = false;
    public void set_display_region (string locale) {
        update_region_lock = true;
        region_combobox.active_id = locale;
        region_checkbutton.active = true;
        update_region_lock = false;
    }

    bool update_format_lock = false;
    public void set_display_format (string locale) {
        update_format_lock = true;
        format_combobox.active_id = locale;
        format_checkbutton.active = true;
        update_format_lock = false;
    }

    void on_language_activated () {
        if (update_region_lock) 
            return;

        language_changed (UpdateType.LANGUAGE, region_combobox.get_active_id ());
    }

    void on_format_activated () {
        if (update_format_lock) 
            return;

        language_changed (UpdateType.FORMAT, format_combobox.get_active_id ());

    }

    void on_language_changed () {
        if (!region_checkbutton.active)
            return;

        on_language_activated ();
    }

    void on_format_changed () {
        if (!format_checkbutton.active)
            return;

        on_format_activated ();
    }

    public void clear () {
        update_format_lock = true;
        update_region_lock = true;
        region_combobox.remove_all ();
        format_combobox.remove_all ();
        update_format_lock = false;
        update_format_lock = false;
    }

    public void add_language (string locale) {
        if (("_" in locale) == false)
            return;

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
        var country_short = country.replace ("(%s)".printf (region), "");

        update_region_lock = true;
        region_combobox.append (locale, country_short);
        update_region_lock = false;
    }

    public void add_locale (string locale) {
        var country = Gnome.Languages.get_country_from_locale (locale, null);

        var country_short = country.replace ("(%s)".printf (region), "");
        if (country != null) {
            update_format_lock = true;
            format_combobox.append (locale, country_short);
            update_format_lock = false;
            format_combobox.show ();
            format_checkbutton.show ();
        }
    }

    public void hide_delete () {
        delete_button.hide ();
    }

    public void show_delete () {
        delete_button.show ();
    }
}
