/* Copyright 2011-2019 elementary, Inc. (https://elementary.io)
*
* This program is free software: you can redistribute it
* and/or modify it under the terms of the GNU Lesser General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with this program. If not, see http://www.gnu.org/licenses/.
*/

[DBus (name = "org.freedesktop.Accounts.User")]
public interface AccountProxy : GLib.Object {
    public abstract void set_formats_locale (string formats_locale) throws GLib.Error;
    public abstract void set_language (string language) throws GLib.Error;
    public abstract string formats_locale { owned get; }
    public abstract string language { owned get; }
}

[DBus (name = "org.freedesktop.locale1")]
public interface Locale1Proxy : GLib.Object {
    public abstract string[] locale { owned get; }

    public abstract async void set_locale (string[] locale, bool interactive) throws GLib.Error;
    public abstract async void set_x11_keyboard (
        string layout,
        string model,
        string variant,
        string options,
        bool convert,
        bool interactive
    ) throws GLib.Error;
}

namespace SwitchboardPlugLocale {
    public class LocaleManager : Object {
        public bool is_connected { get; private set; default = false; }

        private const string GNOME_DESKTOP_INPUT_SOURCES = "org.gnome.desktop.input-sources";
        private const string GNOME_LOCALE_KEY = "org.gnome.system.locale";
        private const string KEY_INPUT_SOURCES = "sources";
        private const string KEY_INPUT_SELETION = "input-selections";

        private Locale1Proxy locale1_proxy;
        private AccountProxy account_proxy;

        private Settings input_settings;
        private Settings locale_settings;
        private Settings settings;

        private Gnome.XkbInfo xkbinfo;

        construct {
            xkbinfo = new Gnome.XkbInfo ();

            uint uid = (uint)Posix.getuid ();

            input_settings = new Settings (GNOME_DESKTOP_INPUT_SOURCES);
            locale_settings = new Settings (GNOME_LOCALE_KEY);

            try {
                var connection = Bus.get_sync (BusType.SYSTEM);
                locale1_proxy = connection.get_proxy_sync<Locale1Proxy> (
                    "org.freedesktop.locale1",
                    "/org/freedesktop/locale1",
                    DBusProxyFlags.NONE
                );
                account_proxy = connection.get_proxy_sync<AccountProxy> (
                    "org.freedesktop.Accounts",
                    "/org/freedesktop/Accounts/User%u".printf (uid),
                    DBusProxyFlags.NONE
                );
            } catch (IOError e) {
                critical (e.message);
            }

            settings = new Settings ("io.elementary.settings.locale");
            settings.changed.connect (on_settings_changed);

            is_connected = account_proxy != null && locale1_proxy != null;
        }

        private void on_settings_changed (string key) {
            if (key == KEY_INPUT_SELETION) {
                var map_array = settings.get_value (KEY_INPUT_SELETION);
                var iter = map_array.iterator ();

                string? k = null;
                string? value = null;

                var map = new Gee.HashMap<string, string> ();

                while (iter.next ("(ss)", &k, &value)) {
                    map.@set (k, value);
                }
            }
        }

        /*
         * user related stuff
         */
        public void set_user_language (string language) {
            debug ("Setting user language to %s", language);

            try {
                account_proxy.set_language (language);
            } catch (Error e) {
                critical (e.message);
            }
        }

        public string get_user_language () {
            // AccountsService on Ubuntu seems to strip off the codepage, so we put it back here
            // so that we can match it against the locales installed on the system
            var lang = account_proxy.language;
            if (!lang.contains (".UTF-8")) {
                lang = lang + ".UTF-8";
            }

            return lang;
        }

        public void set_user_format (string language) {
            debug ("Setting user format to %s", language);

            try {
                account_proxy.set_formats_locale (language);
            } catch (Error e) {
                warning ("Error setting formats on AccountsService: %s", e.message);
            }

            // Also set the format on the GNOME GSettings key as this is used on
            // other distros where the Ubuntu-specific `formats_locale` extension isn't
            // available
            locale_settings.set_string ("region", language);
        }

        public string get_user_format () {
            // The `formats_locale` property is specific to Ubuntu, so check it exists before
            // returning the value
            if (account_proxy.formats_locale != null && account_proxy.formats_locale != "") {
                return account_proxy.formats_locale;
            }

            // If the Ubuntu-specific setting isn't available, we use the GNOME GSettings key
            // which controls the user formats on other distros
            var user_format = locale_settings.get_string ("region");
            if (user_format != "") {
                return user_format;
            }

            // If the GNOME key isn't set, we're using the default for the user's locale, which
            // we can get with setlocale. We use LC_MONETARY here, but when set with the plug,
            // all of the locale categories will have the same value, so this should be right
            string? monetary = Intl.setlocale (LocaleCategory.MONETARY, null);
            if (monetary != null) {
                return monetary;
            }

            // If all of these attempts have failed, fall back to the system locale, or
            // in the worst case just en_US
            return get_system_locale () ?? "en_US.UTF-8";
        }

        public string? get_system_locale () {
            foreach (unowned var locale in locale1_proxy.locale) {
                if (locale.has_prefix ("LANG=")) {
                    return locale.replace ("LANG=", "");
                }
            }

            return null;
        }

        public async void apply_to_system (string language, string? format) {
            string[] locale = {"LANG=%s".printf (language)};

            if (format != null) {
                locale += "LC_TIME=%s".printf (format);
                locale += "LC_NUMERIC=%s".printf (format);
                locale += "LC_MONETARY=%s".printf (format);
                locale += "LC_MEASUREMENT=%s".printf (format);
            }

            yield locale1_proxy.set_locale (locale, true);

            string layouts = "";
            string variants = "";

            string l;
            string v;

            var variant = input_settings.get_value (KEY_INPUT_SOURCES);
            var nr_keymaps = (int)variant.n_children ();

            for (int i = 0; i < nr_keymaps; i++) {
                var entry = variant.get_child_value (i);

                var code = entry.get_child_value (1).get_string ();

                xkbinfo.get_layout_info (code, null, null, out l, out v);

                layouts += l;
                variants += v;

                if (i < nr_keymaps - 1) {
                    layouts += ",";
                    variants += ",";
                }
            }

            locale1_proxy.set_x11_keyboard (
                layouts,
                "",
                variants,
                "",
                true,
                true
            );
        }

        private static LocaleManager? instance = null;

        public static unowned LocaleManager get_default () {
            if (instance == null) {
                instance = new LocaleManager ();
            }
            return instance;
        }
    }
}
