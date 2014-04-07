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

    LocaleManager lm;

    public Plug () {
        Object (category: Category.PERSONAL,
                code_name: "system-pantheon-locale",
                display_name: _("Locale"),
                description: _("Shows locales information…"),
                icon: "preferences-desktop-locale");

        lm = LocaleManager.init ();
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
        if (box == null) {
            //setup_info ();
            setup_ui ();
        }
        return box;
    }
    
    public override void shown () {
                //init_dbus ();

        var langs = Gnome.Languages.get_all_locales ();

        foreach (var lang in langs) {
            locales_box.add_locale (lang);
            message("Languags: %s", lang);
        }
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
        box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        box.get_style_context ().add_class ("background");
        //box.margin = 12;
        message("before lang list");
        locales_box = new LanguageList ();
        locales_box.margin = 12;
        message("after list");
        choose_hint = new Gtk.Label (_("Choose your language:"));
        choose_hint.halign = Gtk.Align.START;
        box.pack_start (choose_hint, false, false);

        box.pack_start (locales_box, true, false);

        
        /*// Let's make sure this looks like the About dialogs
        main_grid.get_style_context ().add_class (Granite.StyleClass.CONTENT_VIEW);

        // Create the section about elementary OS
        var logo = new Gtk.Image.from_icon_name ("distributor-logo", Gtk.icon_size_register ("LOGO", 100, 100));

        var title = new Gtk.Label (os);
        title.use_markup = false;
        Granite.Widgets.Utils.apply_text_style_to_label (Granite.TextStyle.TITLE, title);
        title.set_alignment (0, 0);

        var version = new Gtk.Label (_("Version") + ": " + version + " \"" + codename + "\" ( " + arch + " )");
        version.set_alignment (0, 0);
        version.set_selectable (true);
        
        if (is_ubuntu != null) {
            based_off = new Gtk.Label (_("Built on") + ": " + is_ubuntu + " " + ubuntu_version + " ( \"" + ubuntu_codename + "\" )");
            based_off.set_alignment (0, 0);
            based_off.set_selectable (true);
        }

        var website_label = new Gtk.Label (null);
        website_label.set_markup ("<a href=\"http://elementaryos.org/\">http://elementaryos.org</a>");
        website_label.set_alignment (0, 0);

        var details = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        details.pack_start (title, false, false, 0);
        details.pack_start (version, false, false, 0);
        details.pack_start (based_off, false, false, 0);
        details.pack_start (website_label, false, false, 0);

        var elementary_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        elementary_box.pack_start (logo, false, false, 0);
        elementary_box.pack_start (details, false, false, 0);

        // Hardware title
        var hardware_title = new Gtk.Label (null);
        hardware_title.set_markup (("<b><span size=\"x-large\">%s</span></b>").printf(_("Hardware:")));
        hardware_title.set_alignment (0, 0);

        // Hardware labels
        var processor_label = new Gtk.Label (_("Processor:"));
        processor_label.set_alignment (1, 0);

        var memory_label = new Gtk.Label (_("Memory:"));
        memory_label.set_alignment (1, 0);

        var graphics_label = new Gtk.Label (_("Graphics:"));
        graphics_label.set_alignment (1, 0);

        var hdd_label = new Gtk.Label (_("Storage:"));
        hdd_label.set_alignment (1, 0);

        // Hardware info
        var processor_info = new Gtk.Label (processor);
        processor_info.set_alignment (0, 0);
        processor_info.set_margin_left (6);
        processor_info.set_selectable (true);
        processor_info.set_line_wrap (false);

        var memory_info = new Gtk.Label (memory);
        memory_info.set_alignment (0, 0);
        memory_info.set_margin_left (6);
        memory_info.set_selectable (true);

        var graphics_info = new Gtk.Label (graphics);
        graphics_info.set_alignment (0, 0);
        graphics_info.set_margin_left (6);
        graphics_info.set_selectable (true);
        graphics_info.set_line_wrap (false);

        var hdd_info = new Gtk.Label (hdd);
        hdd_info.set_alignment (0, 0);
        hdd_info.set_margin_left (6);
        hdd_info.set_selectable (true);

        // Hardware grid
        var hardware_grid = new Gtk.Grid ();
        hardware_grid.set_row_spacing (1);
        hardware_grid.attach (hardware_title, 0, 0, 100, 30);
        hardware_grid.attach (processor_label, 0, 40, 100, 25);
        hardware_grid.attach (memory_label, 0, 80, 100, 25);
        hardware_grid.attach (graphics_label, 0, 120, 100, 25);
        hardware_grid.attach (hdd_label, 0, 160, 100, 25);
        hardware_grid.attach (processor_info, 100, 40, 100, 25);
        hardware_grid.attach (memory_info, 100, 80, 100, 25);
        hardware_grid.attach (graphics_info, 100, 120, 100, 25);
        hardware_grid.attach (hdd_info, 100, 160, 100, 25);

        // Help button
        const string HELP_BUTTON_STYLESHEET = """
            .help_button {
                border-radius: 200px;
            }
        """;

        var help_button = new Gtk.Button.with_label ("?");

        Granite.Widgets.Utils.set_theming (help_button, HELP_BUTTON_STYLESHEET, "help_button",
                           Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        help_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("http://elementaryos.org/support", null);
            } catch (Error e) {
                warning (e.message);
            }
        });

        help_button.size_allocate.connect ( (alloc) => {
            help_button.set_size_request (alloc.height, -1);
        });

        // Translate button
        var translate_button = new Gtk.Button.with_label (_("Translate"));
        translate_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://translations.launchpad.net/elementary", null);
            } catch (Error e) {
                warning (e.message);
            }
        });

        // Bug button
        var bug_button = new Gtk.Button.with_label (_("Report a Problem"));
        bug_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri (bugtracker_url, null);
            } catch (Error e) {
                warning (e.message);
            }
        });

        // Upgrade button
        var upgrade_button = new Gtk.Button.with_label (_("Check for Upgrades"));
        upgrade_button.clicked.connect (() => {
            try {
                Process.spawn_command_line_async("update-manager");
            } catch (Error e) {
                warning (e.message);
            }
        });

        // Create a box for the buttons
        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        button_box.pack_start (help_button, false, false, 0);
        button_box.pack_start (translate_button, true, true, 0);
        button_box.pack_start (bug_button, true, true, 0);
        button_box.pack_start (upgrade_button, true, true, 0);
        
        // Fit everything in a box
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        box.pack_start (elementary_box, false, false, 20);
        box.pack_start (hardware_grid, false, false, 40);
        box.pack_end (button_box, false, false, 0);
        box.set_margin_bottom(20);

        // Let's align the box and add it to the plug
        var halign = new Gtk.Alignment ((float) 0.5, 0, 0, 1);
        halign.add (box);
        main_grid.add (halign);

        */
        box.show_all ();
    }
}


public Switchboard.Plug get_plug (Module module) {
    debug ("Activating About plug");
    var plug = new Locale.Plug ();
    return plug;
}