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

    LanguageList language_list;

    LocaleManager lm;

    Gtk.ScrolledWindow sw;

    public Plug () {

        Object (category: Category.PERSONAL,
                code_name: "system-pantheon-locale",
                display_name: _("Locale"),
                description: _("Shows locales information…"),
                icon: "preferences-desktop-locale");
        
    }

    public override Gtk.Widget get_widget () {
        if (sw == null) {
            setup_ui ();
            setup_info ();
        }
        return sw;
    }

    void setup_info () {
        lm = LocaleManager.get_default ();

        lm.connected.connect (() => {
            language_list.reload_languages();
        });

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

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        box.margin = 24;

        try {
            var provider = new Gtk.CssProvider();
            provider.load_from_data ("
                .rounded-corners {
                    border-radius: 5px;
                }

                .insensitve {
                    color: #ccc;
                }

                .bg1 {background-color: #444;}
                .bg2 {background-color: #666;}
                .bg3 {background-color: #888;}
                .bg4 {background-color: #aaa;}
            ", 400);

            Gtk.StyleContext.add_provider_for_screen (sw.get_style_context ().get_screen (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Could not set styles");
        }


        language_list = new LanguageList ();
        language_list.valign = Gtk.Align.START;


        // positioning hack
        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        var label_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        label_box.homogeneous = true;
        var label_right_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        label_right_box.homogeneous = true;
        //label_right_box.get_style_context().add_class ("bg1");


        var choose_language_hint = new Gtk.Label (_("Choose your language:"));
        var choose_format_hint = new Gtk.Label (_("Numbers and dates:"));
        var choose_input_hint = new Gtk.Label (_("Keyboard input:"));

        choose_language_hint.halign = Gtk.Align.START;
        choose_format_hint.halign = Gtk.Align.START;
        choose_input_hint.halign = Gtk.Align.START;

        var delete_image = new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.MENU);
        delete_image.opacity = 0;


        label_box.pack_start (choose_language_hint, true, true);
        label_box.pack_start (label_right_box, true, true);
        top_box.pack_start (label_box, true, true);
        top_box.pack_end (delete_image, false, false);

        label_right_box.pack_start (choose_format_hint, true, true);
        label_right_box.pack_start (choose_input_hint, true, true);
        box.pack_start (top_box, false, false);

        box.pack_start (language_list, true, true);

        var apply_button = new Gtk.Button.with_label (_("Apply system-wide"));
        apply_button.clicked.connect (on_applied_to_systen);
        box.pack_start (apply_button, false, false);

        apply_button.show_all ();

        sw.add (box);
        top_box.show_all ();
        label_box.show_all ();
        language_list.show ();
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