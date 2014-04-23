//
//  Copyright (C) 2012 Ivo Nunes
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace LC {
    public static const string LANG = "LANG";
    public static const string NUMERIC = "LC_NUMERIC";
    public static const string TIME = "LC_TIME";
    public static const string MONETARY = "LC_MONETARY";
     public static const string MESSAGES = "LC_MESSAGES";
    public static const string PAPER = "LC_PAPER";
    public static const string NAME = "LC_NAME";
    public static const string ADDRESS = "LC_ADDRESS";
    public static const string MEASUREMENT = "LC_MEASUREMENT";
    public static const string TELEPHONE = "LC_TELEPHONE";
    public static const string IDENTIFICATION = "LC_IDENTIFICATION";
}

public class Locale.Plug : Switchboard.Plug {

    private string os;
    private string website_url;
    private string bugtracker_url;
    private string codename;
    private string version;
    private string arch;
    private string processor;
    private string memory;
    private string graphics;
    private string hdd;
    private Gtk.Label choose_hint;
    
    
    private string is_ubuntu;
    private string ubuntu_version;
    private string ubuntu_codename;
    private Gtk.Box box;

    string system_language;
    string system_region;

    private LanguageList locales_box;

    
    private DBusProxy session_proxy;

    Gtk.ScrolledWindow sw;

    LocaleManager lm;

    public Plug () {
        Object (category: Category.PERSONAL,
                code_name: "system-pantheon-locale",
                display_name: _("Locale"),
                description: _("Shows locales information…"),
                icon: "preferences-desktop-locale");

        
    }

    void session_proxy_ready () {

    }

    void init_dbus () {
        DBusProxy.create_for_bus.begin (BusType.SESSION,
            DBusProxyFlags.NONE,
            null,
            "org.gnome.SessionManager",
            "/org/gnome/SessionManager",
            "org.gnome.SessionManager",
            null,
            (obj, res) => {
                session_proxy = DBusProxy.create_for_bus.end (res);
                message("dbus connected");
            }
         );

        
    }

 

    void update_language_label () {
        var language = system_language;
        string name = "";

        name = Gnome.Languages.get_language_from_locale (language, language);
   
        message ("Label Text: %s (%s)", name, system_language);

        update_region_label ();
    }

    void update_region_label () {
        var region = system_region;
        string name = "";

        name = Gnome.Languages.get_country_from_locale (region, region);
   
        message ("Region Text: %s (%s)", name, system_region);
    }
    
    public override Gtk.Widget get_widget () {
        if (sw == null) {
            setup_ui ();
            setup_info ();
        }
        return sw;
    }

    void setup_info () {
        lm = new LocaleManager();
        //locales_box.lm = lm;

        //var langs = Gnome.Languages.get_all_locales ();
        var utils = new Utils ();
        
        locales_box.reload_languages();

    }
    
    public override void shown () {
        
    }
    
    public override void hidden () {
    
    }
    
    public override void search_callback (string location) {
    
    }
    
    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        return new Gee.TreeMap<string, string> (null, null);
    }



    // Wires up and configures initial UI
    private void setup_ui () {

        sw = new Gtk.ScrolledWindow (null, null);

        box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        //box.get_style_context ().add_class ("background");
        box.margin = 24;
        message("before lang list");
        locales_box = new LanguageList ();
        locales_box.valign = Gtk.Align.START;
        //locales_box.margin = 12;
        message("after list");

        // positioning hack
        var label_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        label_box.homogeneous = true;
        var label_right_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        label_right_box.homogeneous = true;

        var choose_language_hint = new Gtk.Label (_("Choose your language:"));
        var choose_format_hint = new Gtk.Label (_("Numbers and dates:"));
        var choose_input_hint = new Gtk.Label (_("Keyboard input:"));

        choose_language_hint.halign = Gtk.Align.START;
        choose_format_hint.halign = Gtk.Align.START;
        choose_input_hint.halign = Gtk.Align.START;


        label_box.pack_start (choose_language_hint, true, true);
        label_box.pack_start (label_right_box, true, true);

        label_right_box.pack_start (choose_format_hint, true, true);
        label_right_box.pack_start (choose_input_hint, true, true);
        box.pack_start (label_box, false, false);

        box.pack_start (locales_box, true, true);

        var apply_button = new Gtk.Button.with_label (_("Apply system-wide"));
        apply_button.clicked.connect (on_applied_to_systen);
        box.pack_start (apply_button, false, false);

        apply_button.show_all ();

        sw.add (box);
        label_box.show_all ();

        choose_hint.show ();
        locales_box.show ();
        box.show ();
        sw.show ();
    }

    void on_applied_to_systen () {
        lm.apply_user_to_system ();
    }
}


public Switchboard.Plug get_plug (Module module) {
    debug ("Activating About plug");
    var plug = new Locale.Plug ();
    return plug;
}