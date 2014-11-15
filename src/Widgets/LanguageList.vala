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

public class LanguageList : Gtk.ListBox {

	public signal void settings_changed ();

    InstallPopover language_popover;
    InstallEntry install_entry;

    UbuntuInstaller li;

    public Gtk.RadioButton language_button = new Gtk.RadioButton (null);
    public Gtk.RadioButton format_button = new Gtk.RadioButton (null);

    LocaleManager lm;

    Gee.HashMap<string, LanguageEntry> languages;
    Gee.HashMap<string, string?> input_sources;

    private const string STYLE = """

        GtkListBox {
            background-color: transparent;
        }

    """;

    public LanguageList () {

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_data (STYLE, STYLE.length);
        get_style_context ().add_provider (css_provider, -1);

        valign = Gtk.Align.START;
        vexpand = true;
        hexpand = true;
        margin_start = 24;
        margin_end = 24;

        set_activate_on_single_click(true);
        set_sort_func (sort_func);
        set_selection_mode (Gtk.SelectionMode.NONE);
        //set_header_func (header_func);
        set_filter_func (filter_func);

        languages = new Gee.HashMap<string, LanguageEntry> ();
        input_sources = new Gee.HashMap<string, string?> ();

        li = new UbuntuInstaller ();
        li.install_finished.connect (on_install_finished);
        li.remove_finished.connect (on_remove_finished);
        
        lm = LocaleManager.get_default ();
        
        install_entry = new InstallEntry();
        language_popover = new InstallPopover (install_entry.label);
        language_popover.language_selected.connect (on_install_language);

        add (install_entry);

        show ();
  
    }

    bool update_lock = true;

    public void reload_languages () {

        var langs = Utils.get_installed_languages ();
        foreach (var lang in langs) {
            add_language (lang);
        }

        var locales = Utils.get_installed_locales ();
        foreach (var locale in locales) {
            add_locale (locale);
        }

        requery_display ();

    }

    void requery_display () {

        var lang = lm.get_user_language ();
        var region = lm.get_user_format ();
        var inputs = lm.get_user_inputmaps ();

        update_lock = true;

        select_language (lang);
        select_format (region);
        select_inputs (inputs);

        update_lock = false;

    }

    /*
     * update selections
     */

    void select_language (string language) {

        var lang = languages.get (language[0:2]);
        lang.set_display_region (language);

    }

    void select_format (string locale) {

        var lang = languages.get (locale[0:2]);
        lang.set_display_format(locale[0:5]);

    }

    void select_inputs (Gee.HashMap<string, string> map) {
        
        map.@foreach ((entry) => {
            input_sources.@set (entry.key, entry.value);
            var lang = languages.get (entry.key);
            lang.set_display_input (entry.value);
            return true;
        });

    }

    void on_install_language (string lang) {
        
        li.install (lang);
        install_entry.install_started ();
        
    }

    void on_install_finished (string language) {
        
        reload_languages ();
        install_entry.install_complete ();

    }

    void on_deletion_requested (string locale) {
        
        li.remove (locale);

    }

    void on_remove_finished (string langcode) {
        
        var widget = languages.@get (langcode);
        remove (widget);
        languages.unset (langcode);

        if (languages.size == 1) {
            languages.@foreach ((entry) => {
                entry.value.hide_delete ();
                return true;
            });
        }

    }

    public void add_language(string locale) {

        var langcode = locale.substring (0, 2);

        if (languages.has_key (langcode)) {
            var entry = languages.@get (langcode);
            entry.add_language (locale);

            return;
        }

        var l_entry = new LanguageEntry(locale, this);

        languages.@set (langcode, l_entry);

        l_entry.language_changed.connect (on_language_changed);
        l_entry.input_changed.connect (on_input_changed);
        l_entry.deletion_requested.connect (on_deletion_requested);

        add (l_entry);
        l_entry.show ();


        // update visibility of delete button
        if (languages.size == 1) {
            languages.@foreach ((entry) => {
                entry.value.hide_delete ();
                return true;
            });
        } else {
            languages.@foreach ((entry) => {
                entry.value.show_delete ();
                return true;
            });
        }
        
    }

    public void add_locale (string locale) {
        var langcode = locale.substring (0, 2);

        if (languages.has_key (langcode)) {
            var entry = languages.@get (langcode);
            entry.add_locale (locale);

            return;
        } else {
            warning ("Found locale without corresponding language pack");
        }
    }



    void on_language_changed (UpdateType type, string lang) {
        if (update_lock) 
            return;

        switch (type) {
            case UpdateType.LANGUAGE:
                lm.set_user_language (lang);
                break;
            case UpdateType.FORMAT:
                lm.set_user_format (lang+".UTF-8");
                break;
        }

        settings_changed ();
        
    }


    void on_input_changed (string langcode, string inputcode, bool added) {
        
        if (update_lock)
            return;

        if (!added) {
            input_sources.@unset (langcode);
        } else {
            input_sources.@set (langcode, inputcode);
        }

        VariantBuilder builder2 = new VariantBuilder (new VariantType ("a(ss)") );      
        VariantBuilder builder = new VariantBuilder (new VariantType ("a(ss)") );       
        input_sources.@foreach((entry) => {
            message ("('%s', '%s')", "xkb", entry.value);
            builder2.add ("(ss)", entry.key, entry.value);
            builder.add ("(ss)", "xkb", entry.value);
            return true;
        }); 

        lm.set_input_language (builder.end (), builder2.end ());
   
    }

    /*
     * Gtk.ListBox functions
     */

    public override void row_activated (Gtk.ListBoxRow row) {

        if (row is InstallEntry) {
            language_popover.show_all ();
        } else {
            var locale = row as LanguageEntry;
            locale.check_button.set_active (true);
        }

    }

    int sort_func (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        
        var first = row1 as BaseEntry;
        var second = row2 as BaseEntry;

        var string1 = first.region + " " + first.country;
        var string2 = second.region + " " + second.country;
        var diff = (int) (string1.collate (string2) );
        return diff;

    }

    /*void header_func (Gtk.ListBoxRow? row, Gtk.ListBoxRow? before) {
        
        if (before != null) {
            row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        }

    }*/

    bool filter_func (Gtk.ListBoxRow row) {

        return true;

    }
}
