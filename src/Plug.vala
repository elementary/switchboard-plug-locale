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

    Gtk.InfoBar infobar;
    Gtk.InfoBar missing_lang_infobar;
    Gtk.Grid grid;
    Gtk.Box top_box;

    public Plug () {

        Object (category: Category.PERSONAL,
                code_name: "system-pantheon-locale",
                display_name: _("Region & Language"),
                description: _("Change your region and language settings"),
                icon: "preferences-desktop-locale");
        
    }

    public override Gtk.Widget get_widget () {
        if (grid == null) {
            grid = new Gtk.Grid ();

        }
        return grid;
    }

    void setup_info () {
        lm = LocaleManager.get_default ();

        lm.connected.connect (() => {
            language_list.reload_languages();
        });

    }
    
    public override void shown () {
        setup_ui ();
        setup_info ();
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

            Gtk.StyleContext.add_provider_for_screen (grid.get_style_context ().get_screen (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Could not set styles");
        }

        var sw = new Gtk.ScrolledWindow (null, null);

        grid.column_homogeneous = true;
        grid.row_spacing = 5;

        language_list = new LanguageList ();
        language_list.valign = Gtk.Align.START;
        sw.add (language_list);

        var header_entry = new BaseEntry ();
        header_entry.hexpand = true;
        header_entry.margin_left = 24;
        header_entry.margin_right = 24;

        var choose_language_hint = new Gtk.Label (_("Choose your language:"));
        choose_language_hint.hexpand = true;
        var choose_format_hint = new Gtk.Label (_("Numbers and dates:"));
        var choose_input_hint = new Gtk.Label (_("Keyboard input:"));

        choose_language_hint.halign = Gtk.Align.START;
        choose_format_hint.halign = Gtk.Align.START;
        choose_input_hint.halign = Gtk.Align.START;

        header_entry.left_grid.attach (choose_language_hint, 0, 0, 1, 1);
        header_entry.right_grid.attach (choose_format_hint, 0, 0, 1, 1);
        header_entry.right_grid.attach (choose_input_hint, 1, 0, 1, 1);
        var spacer = new Gtk.Image.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.MENU);
        spacer.set_opacity (0);
        header_entry.settings_grid.add (spacer);

        infobar = new Gtk.InfoBar ();
        infobar.message_type = Gtk.MessageType.INFO;
        infobar.no_show_all = true;
        var content = infobar.get_content_area () as Gtk.Container;
        var label = new Gtk.Label (_("Some changes will not take effect until you log out"));
        content.add (label);

        language_list.settings_changed.connect (() => {
            infobar.no_show_all = false;
            infobar.show_all ();
        });

        var install_infobar = new InstallInfoBar ();
        install_infobar.hide ();
        install_infobar.cancel_clicked.connect (()=>{
            language_list.cancel_install ();
        });

        missing_lang_infobar = new Gtk.InfoBar ();
        missing_lang_infobar.message_type = Gtk.MessageType.INFO;

        var missing_content = missing_lang_infobar.get_content_area () as Gtk.Box;

        var missing_label = new Gtk.Label (_("Language support is not installed completely"));

        var install_missing = new Gtk.Button.with_label (_("Complete Installation"));
        install_missing.clicked.connect (()=>{
            missing_lang_infobar.hide ();

            language_list.install_missing_languages ();
        });
        language_list.check_missing_finished.connect ((missing)=>{
            if (missing.length>0) {
                missing_lang_infobar.show ();
                missing_lang_infobar.show_all ();
            } else {
                missing_lang_infobar.hide ();
            }
        });

        missing_content.pack_start (missing_label, false);
        missing_content.pack_end (install_missing, false);

        language_list.settings_changed.connect (() => {
            infobar.no_show_all = false;
            infobar.show_all ();
        });
        language_list.progress_changed.connect((progress)=>{
            install_infobar.set_progress (progress);
            install_infobar.set_cancellable (language_list.install_cancellable);
            install_infobar.set_transaction_mode (language_list.get_transaction_mode ());
        });

        try {

            var permission = new Polkit.Permission.sync ("org.freedesktop.locale1.set-locale", Polkit.UnixProcess.new (Posix.getpid ()));
            var apply_button = new Gtk.LockButton (permission);

            apply_button.label = _("Apply for login screen, guest account and new users");
            apply_button.halign = Gtk.Align.CENTER;
            apply_button.margin = 12;
            grid.attach (apply_button, 0, 6, 4, 1);

            permission.notify["allowed"].connect (() => {
                if (permission.allowed) {
                    on_applied_to_system();
                    permission.impl_update (false, true, true);
                }
            });

        } catch (Error e) {
                critical (e.message);
        }


        sw.show ();
        header_entry.show_all ();

        grid.attach (infobar, 0, 0, 4, 1);
        grid.attach (missing_lang_infobar, 0, 1, 4, 1);
        grid.attach (install_infobar, 0, 2, 4, 1);
        grid.attach (header_entry, 0, 3, 4, 1);
        grid.attach (top_box, 0, 4, 4, 1);
        grid.attach (sw, 0, 5, 4, 1);
        grid.show ();

    }

    void on_applied_to_system () {
        lm.apply_user_to_system ();
        infobar.no_show_all = false;
        infobar.show_all ();
    }
}


public Switchboard.Plug get_plug (Module module) {
    debug ("Activating About plug");
    var plug = new Locale.Plug ();
    return plug;
}
