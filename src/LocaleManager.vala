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

/*[DBus (name = "org.freedesktop.locale1")]
  public interface LocaleProxy: GLib.Object
  {
    [DBus (signature = "(asb)")]
    public abstract void set_locale (string[] locale, bool user_interaction) throws IOError;
    public abstract void set_x11_keyboard (string layout, string model, string variant, string options, bool convert, bool user_interaction) throws IOError;
    public abstract string[] locale  { owned get; }
    public abstract string x11_layout  { owned get; }
    public abstract string x11_model  { owned get; }
  }
*/

[DBus (name = "org.freedesktop.Accounts.User")]
  public interface AccountProxy: GLib.Object
  {
    public abstract void set_formats_locale (string formats_locale) throws IOError;
    public abstract void set_language (string language) throws IOError;
    public abstract string formats_locale  { owned get; }
    public abstract string language  { owned get; }
  }

namespace SwitchboardPlugLocale {
    public class LocaleManager : Object {
        static const string GNOME_SYSTEM_LOCALE = "org.gnome.system.locale";
        static const string KEY_REGION = "region";
        static const string GNOME_DESKTOP_INPUT_SOURCES = "org.gnome.desktop.input-sources";
        static const string KEY_CURRENT_INPUT = "current";
        static const string KEY_INPUT_SOURCES = "sources";
        const string KEY_INPUT_SELETION = "input-selections";

        DBusProxy locale1_proxy;
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
            user = user_manager.get_user_by_id (uid);

            locale_settings = new Settings (GNOME_SYSTEM_LOCALE);
            input_settings = new Settings (GNOME_DESKTOP_INPUT_SOURCES);

            /*Bus.get_proxy.begin<AccountProxy> (BusType.SYSTEM,
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

                    } catch (Error e) {
                        warning ("Could not connect to locale bus");
                    }

            });*/

            Bus.get_proxy.begin<AccountProxy> (BusType.SYSTEM,
                "org.freedesktop.Accounts",
                "/org/freedesktop/Accounts/User%u".printf (uid),
                0,
                null,
                (obj, res) => {
                    try {
                        account_proxy = Bus.get_proxy.end (res);

                        if (account_proxy != null && locale1_proxy != null) {
                            is_connected = true;
                            connected ();
                        }

                        fetch_settings (account_proxy.language, account_proxy.formats_locale);
                    } catch (Error e) {
                        warning ("Could not connect to user account");
                    }

            });

            DBusProxy.create_for_bus.begin (BusType.SYSTEM,
                 DBusProxyFlags.NONE,
                 null,
                 "org.freedesktop.locale1",
                 "/org/freedesktop/locale1",
                 "org.freedesktop.locale1",
                 null,
                 (obj, res) => {
                    try {
                        locale1_proxy = DBusProxy.create_for_bus.end (res);

                        if (account_proxy != null && locale1_proxy != null) {
                            is_connected = true;
                            connected ();
                        }

                    } catch (Error e) {
                        warning ("Could not connect to locale1 dbus");
                    }
                }
              );

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
                }


                //language_list.select_inputs (map);
            }
        }


        public void apply_user_to_system () {

            set_system_language_direct (get_user_language (), get_user_format ());
            set_system_input_direct ();

        }

        /* // leading to segfault, would be my preferred way instead of using raw dbus
        void set_system_language (string language, string? format) {

            var list = new Gee.ArrayList<string> ();

            list.add ("LANG=%s".printf (language));
            if (format != null && format != language) {
                list.add ("LC_TIME=%s".printf (format));
                list.add ("LC_NUMERIC=%s".printf (format));
                list.add ("LC_MONETARY=%s".printf (format));
                list.add ("LC_MEASUREMENT=%s".printf (format));
            }

            try {
                locale_proxy.set_locale (list.to_array (), true);
            } catch (Error e) {
                warning (e.message);
            }

        }*/

        void set_system_language_direct (string language, string? format) {

            VariantBuilder builder = new VariantBuilder (new VariantType ("as") );
            builder.add ("s", "LANG=%s".printf (language));
            if (format != null) {
                builder.add ("s", "LC_TIME=%s".printf (format));
                builder.add ("s", "LC_NUMERIC=%s".printf (format));
                builder.add ("s", "LC_MONETARY=%s".printf (format));
                builder.add ("s", "LC_MEASUREMENT=%s".printf (format));
            }

            var variant = new Variant ("(asb)", builder, true);
            locale1_proxy.call.begin ("SetLocale", variant, DBusCallFlags.NONE, -1, null);


        }

        void set_system_input_direct () {

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
            locale1_proxy.call.begin ("SetX11Keyboard", insert, DBusCallFlags.NONE, -1, null);
            // TODO
        }


        /*
         * user related stuff
         */
        public void set_user_language (string language) {
            debug("Setting user language to %s", language);

            try {
                account_proxy.set_language (language);
            } catch (Error e) {
                critical (e.message);
            }
        }

        public string get_user_language () {
            return account_proxy.language;
        }

        public void set_user_format (string language) {
            debug("Setting user format to %s", language);

            try {
                account_proxy.set_formats_locale (language);
            } catch (Error e) {
                critical (e.message);
            }
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
        
        private void localectl_set_locale (string locale, string? format = null) throws GLib.Error {
            debug ("setting system-wide locale via localectl");
            if (Utils.get_permission ().allowed) {
                string output;
                int status;
                string cli = "/usr/bin/localectl";
                string command = "set-locale";

                try {
                    if (format == null) {
                        Process.spawn_sync (null,
                            {"pkexec", cli, command, locale}, 
                            Environ.get (), 
                            SpawnFlags.SEARCH_PATH, 
                            null, out output, 
                            null, out status);
                        if (output != "")
                            critical ("localectl failed to set locale");
                    } else {
                        Process.spawn_sync (null,
                            {"pkexec", cli, command, locale, "LC_TIME=%s".printf (format),
                             "LC_NUMERIC=%s".printf (format), "LC_MONETARY=%s".printf (format),
                             "LC_MEASUREMENT=%s".printf (format)}, 
                            Environ.get (),
                            SpawnFlags.SEARCH_PATH,
                            null, out output,
                            null, out status);
                        if (output != "")
                            critical ("localectl failed to set locale");
                    }
                } catch (Error e) {
                    critical ("localectl failed to set locale");
                    throw e;
                }
            }
        }

        private void localectl_set_x11_keymap (string layouts, string variants) throws GLib.Error {
            if (Utils.get_permission ().allowed) {
                string output;
                int status;
                string cli = "/usr/bin/localectl";
                string command = "set-x11-keymap";

                try {
                    Process.spawn_sync (null,
                        {"pkexec", cli, command, layouts, "", variants},
                        Environ.get (),
                        SpawnFlags.SEARCH_PATH,
                        null, out output,
                        null, out status);

                    if (output != "")
                        critical ("localectl failed to set x11 keymap");
                } catch (Error e) {
                    critical ("localectl failed to set x11 keymap");
                    throw e;
                }
            }
        }
        
          public void apply_to_system (string language, string? format) {
            set_system_language (language, format);
            set_system_input ();
        }

        private void set_system_language (string language, string? format) {
            /*
             * This is a temporary solution for setting the system-wide locale.
             * I am assuming systemd in version 204 (which we currently ship from Ubuntu repositories)
             * is broken as SetLocale does not recognize the aquired polkit permission. Maybe that is
             * intended, but I do not believe this. May be fixed in a later version of systemd and should
             * be reversed (TODO) when introducing a newer version of systemd to elementary OS.
             */

            /*var list = new Gee.ArrayList<string> ();

            list.add ("LANG=%s.UTF-8".printf (language));
            if (format != null && format != language) {
                list.add ("LC_TIME=%s".printf (format));
                list.add ("LC_NUMERIC=%s".printf (format));
                list.add ("LC_MONETARY=%s".printf (format));
                list.add ("LC_MEASUREMENT=%s".printf (format));
            }*/

            try {
                localectl_set_locale ("LANG=%s.utf8".printf (language), format);
                //locale_proxy.set_locale (list.to_array (), true);
            } catch (Error e) {
                warning (e.message);
            }
        }

        private void set_system_input () {
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

            try {
                /* TODO: temporary solution for systemd-localed polkit problem */

                localectl_set_x11_keymap (layouts, variants);
                //locale_proxy.set_x11_keyboard (layouts, "", variants, "", true, true);
            } catch (Error e) {
                warning (e.message);
            }
        }

        static LocaleManager? instance = null;

        public static LocaleManager get_default () {
            if (instance == null) {
                instance = new LocaleManager ();
            }
            return instance;
        }
    }
}
