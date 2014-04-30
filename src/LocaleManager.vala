 
[DBus (name = "org.freedesktop.locale1")]
  public interface LocaleProxy: GLib.Object
  {
    public abstract async void set_locale (string[] locale, bool user_interaction) throws IOError;
    public abstract async void set_x11_keyboard (string layout, string model, string variant, string options, bool convert, bool user_interaction) throws IOError;
    //public abstract string get_x11_layout() throws IOError;
    //public abstract string get_x11_model()throws IOError;
  }

[DBus (name = "org.freedesktop.Accounts.User")]
  public interface AccountProxy: GLib.Object
  {
    //public abstract async void set_locale (string[] locale, bool user_interaction) throws IOError;
    //public abstract async string set_x11_keyboard (string layout, string model, string variant, string options, bool convert, bool user_interaction) throws IOError;
    //public abstract string get_x11_layout();
    public abstract async void set_formats_locale (string formats_locale) throws IOError;
    public abstract async void set_language (string language) throws IOError;
    public abstract string formats_locale  { owned get; }
    public abstract string language  { owned get; }
  }

public class LocaleManager : Object {
    static const string GNOME_SYSTEM_LOCALE = "org.gnome.system.locale";
    static const string KEY_REGION = "region";
    static const string GNOME_DESKTOP_INPUT_SOURCES = "org.gnome.desktop.input-sources";
    static const string KEY_CURRENT_INPUT = "current";
    static const string KEY_INPUT_SOURCES = "sources";
    const string KEY_INPUT_SELETION = "input-selections";

    DBusProxy localed_proxy;
    private LocaleProxy locale_proxy;
    private AccountProxy account_proxy;

    Act.UserManager user_manager;
    Act.User user;

    Settings locale_settings;
    Settings input_settings;
    Settings settings;

    Gnome.XkbInfo xkbinfo;

    public signal void loaded_user (string language, string format, Gee.HashMap<string, string> inputs);
    
    public signal void connected ();

    bool is_connected = false;

    private LocaleManager () {

        xkbinfo = new Gnome.XkbInfo ();

        user_manager = Act.UserManager.get_default ();
        uint uid = (uint)Posix.getuid();
        message ("uid: %u", uid);
        user = user_manager.get_user_by_id (uid);

        locale_settings = new Settings (GNOME_SYSTEM_LOCALE);
        input_settings = new Settings (GNOME_DESKTOP_INPUT_SOURCES);

        Bus.get_proxy.begin<AccountProxy> (BusType.SYSTEM,
            "org.freedesktop.locale1",
            "/org/freedesktop/locale1",
            0,
            null,
            (obj, res) => {
                try {
                    locale_proxy = Bus.get_proxy.end (res);
                    
                    if (account_proxy != null && locale_proxy != null) {
                        is_connected = true;
                        connected ();
                    }
                    warning ("localed proxy connected");
                } catch (Error e) {
                    warning ("Could not connect to locale bus");
                }

        });

        Bus.get_proxy.begin<AccountProxy> (BusType.SYSTEM,
            "org.freedesktop.Accounts",
            "/org/freedesktop/Accounts/User1000",
            0,
            null,
            (obj, res) => {
                try {
                    account_proxy = Bus.get_proxy.end (res);
                    
                    if (account_proxy != null && locale_proxy != null) {
                        is_connected = true;
                        connected ();
                    }

                    fetch_settings (account_proxy.language, account_proxy.formats_locale);
                } catch (Error e) {
                    warning ("Could not connect to user account");
                }
                
        });

        settings = new Settings ("org.pantheon.switchboard.plug.locale");
        settings.changed.connect (on_settings_changed);

    }

    void fetch_settings (string language, string format) {

            var map_array = settings.get_value (KEY_INPUT_SELETION);
            var iter = map_array.iterator ();

            string? k = null;
            string? value = null;

            var map = new Gee.HashMap<string, string> ();

            while (iter.next ("(ss)", &k, &value)) {
                map.@set (k, value);
                warning ("clicking %s -> %s", k, value);
            }
            

            loaded_user (language, format, map);
        
    }

    void on_settings_changed (string key) {

        if (key == KEY_INPUT_SELETION) {
            var map_array = settings.get_value (KEY_INPUT_SELETION);
            var iter = map_array.iterator ();

            string? k = null;
            string? value = null;

            var map = new Gee.HashMap<string, string> ();

            while (iter.next ("(ss)", &k, &value)) {
                map.@set (k, value);
                warning ("clicking %s -> %s", k, value);

            }


            //language_list.select_inputs (map);
        }
    }


    public void apply_user_to_system () {
        message("language");
        set_localed_language ();
        //set_localed_format ();
        message("input");
        set_localed_input ();
    }

    public void set_locale_language () {
        string[] langs = new string[1];

        langs[0] = "LANG=%s".printf (get_user_language ());
        /*if (get_user_language () != get_user_format ()) {
            langs[1] = "LC_TIME=%s".printf (get_user_format ());
            langs[2] = "LC_NUMERIC=%s".printf (get_user_format ());
            langs[3] = "LC_MEASUREMENT=%s".printf (get_user_format ());
            langs[4] = "LC_MONETARY=%s".printf (get_user_format ());

        }*/

//      localed_proxy.call ("SetLocale", variant, DBusCallFlags.NONE, -1, null);
        locale_proxy.set_locale.begin (langs, true);
    }

    public void set_localed_language () {

        VariantBuilder builder = new VariantBuilder (new VariantType ("as") );      
        builder.add ("s", "LANG=%s".printf (get_user_language ()));
        if (get_user_language () != get_user_format ()) {
            builder.add ("s", "LC_TIME=%s".printf (get_user_format ()));
            builder.add ("s", "LC_NUMERIC=%s".printf (get_user_format ()));
            builder.add ("s", "LC_MONETARY=%s".printf (get_user_format ()));
            builder.add ("s", "LC_MEASUREMENT=%s".printf (get_user_format ()));
        }
    
        var variant = new Variant ("(asb)", builder, true);
        localed_proxy.call.begin ("SetLocale", variant, DBusCallFlags.NONE, -1, null);
    }

    public void set_localed_input () {

        string layouts = "";
        string variants = "";

        string l;
        string v;

        var variant = input_settings.get_value (KEY_INPUT_SOURCES);
        var nr_keymaps = (int)variant.n_children ();

        for (int i = 0; i < nr_keymaps; i++) {
            var entry = variant.get_child_value (i);

            //var type = entry.get_child_value (0).get_string ();
            var code = entry.get_child_value (1).get_string ();

            xkbinfo.get_layout_info (code, null, null, out l, out v);

            layouts += l;
            variants += v;

            if (i < nr_keymaps-1) {
                layouts += ",";
                variants += ",";
            }
        }

        var insert = new Variant ("(ssssbb)", layouts, "", variants, "", true, true);
        localed_proxy.call.begin ("SetX11Keyboard", insert, DBusCallFlags.NONE, -1, null);
        // TODO
    }


    /*
     * user related stuff
     */
    public void set_user_language (string language) {
        account_proxy.set_language.begin (language);
    }

    public string get_user_language () {
        return account_proxy.language;
    }

    public void set_user_format (string language) {
        account_proxy.set_formats_locale.begin (language);
    }

    public string get_user_format () {
        return account_proxy.formats_locale;
    }

    public Gee.HashMap<string, string> get_user_inputmaps () {
        var map_array = settings.get_value (KEY_INPUT_SELETION);
        var iter = map_array.iterator ();

        string? k = null;
        string? value = null;

        var map = new Gee.HashMap<string, string> ();

        while (iter.next ("(ss)", &k, &value)) {
            map.@set (k, value);
            warning ("clicking %s -> %s", k, value);

        }

        return map;
    }

    public Gee.HashMap<string, string> get_user_inputs () {
        var map_array = settings.get_value (KEY_INPUT_SOURCES);
        var iter = map_array.iterator ();

        string? k = null;
        string? value = null;

        var map = new Gee.HashMap<string, string> ();

        while (iter.next ("(ss)", &k, &value)) {
            map.@set (k, value);
            warning ("clicking %s -> %s", k, value);

        }

        return map;
    }

    public void set_input_language (Variant input_sources, Variant my_map) {

        if (input_sources.get_type_string () == "a(ss)") {
            input_settings.set_value (KEY_INPUT_SOURCES, input_sources);
        }

        if (my_map.get_type_string () == "a(ss)") {
            settings.set_value (KEY_INPUT_SELETION, my_map);
        }


    }

/*
    // LC_xxx=
    public void set_user_format (string language) {
        message("setting location to %s", language);
        user.set_formats_locale (language);
    }
*/
    // LC_xxx=
    public void set_user_location (string language) {
        message("setting location to %s", language);
        user.set_location (language);
    }

    public string get_user_location () {
        return user.get_location ();
    }

    // LC_xxx=
    public void set_user_region (string region) {
        locale_settings.set_string (KEY_REGION, region);
    }

    public string get_user_region () {
        return locale_settings.get_string (KEY_REGION);
    }

    public void set_system_region (string region) {

    }

    static LocaleManager? instance = null;

    public static LocaleManager get_default () {
        if (instance == null) {
            instance = new LocaleManager ();
        }
        return instance;
    }
}