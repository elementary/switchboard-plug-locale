public class LocaleManager : Object {
	static const string GNOME_SYSTEM_LOCALE = "org.gnome.system.locale";
	static const string KEY_REGION = "region";
	static const string GNOME_DESKTOP_INPUT_SOURCES = "org.gnome.desktop.input-sources";

	private DBusProxy localed_proxy;

	Act.UserManager user_manager;
	Act.User user;

	Settings locale_settings;
	Settings input_settings;
	
	public LocaleManager () {

		user_manager = Act.UserManager.get_default ();
		uint uid = (uint)Posix.getuid();
		message ("uid: %u", uid);
		user = user_manager.get_user_by_id (uid);

		locale_settings = new Settings (GNOME_SYSTEM_LOCALE);
		input_settings = new Settings (GNOME_DESKTOP_INPUT_SOURCES);

		DBusProxy.create_for_bus.begin (BusType.SYSTEM,
            DBusProxyFlags.NONE,
            null,
            "org.freedesktop.locale1",
            "/org/freedesktop/locale1",
            "org.freedesktop.locale1",
            null,
            (obj, res) => {
                localed_proxy = DBusProxy.create_for_bus.end (res);
                
                if (localed_proxy == null) {
                    warning ("Failed to connect to localed:");
                }

                //localed_proxy.g_properties_changed.connect (on_localed_properties_changed);
                //on_localed_properties_changed (null, null);
                message("dbus connected");
            }
         );

	}


	// LANG=
	public void set_user_language (string language) {
		user.set_language (language);
	}

	public string get_user_language () {
		return user.get_language ();
	}

	// LANG=
	public void set_user_location (string language) {
		message("setting location to %s", language);
		user.set_location (language);
	}

	public string get_user_location () {
		return user.get_location ();
	}

	// LC_TIME=
	public void set_user_region (string region) {
		locale_settings.set_string (KEY_REGION, region);
	}

	public string get_user_region () {
		return locale_settings.get_string (KEY_REGION);
	}

	public void set_system_region (string region) {

	}

	void on_localed_properties_changed (Variant? changed_properties, string[]? invalidated_properties) {
        message("callback");
        string lang = null;
        string numeric = null;
        string messages = null;
        string time = null;
        string identification = null;
        string measurement = null;
        string telephone = null;
        string address = null;
        string paper = null;
        string monetary = null;
        string name = null;

        var v = localed_proxy.get_cached_property ("Locale");

        if (v != null) {
            message("v is not null");
            string [] strv;

            strv = v.get_strv ();

            for (int i = 0; strv[i] != null; i++) {
                if (strv[i].has_prefix (LC.LANG)) {
                    lang = strv[i].offset(LC.LANG.length+1);

                } else if (strv[i].has_prefix (LC.NUMERIC)) {
                    numeric = strv[i].offset(LC.NUMERIC.length+1);
               
                } else if (strv[i].has_prefix (LC.TIME)) {
                    time = strv[i].offset(LC.TIME.length+1);
                
                } else if (strv[i].has_prefix (LC.MONETARY)) {
                    monetary = strv[i].offset(LC.MONETARY.length+1);
                
                } else if (strv[i].has_prefix (LC.PAPER)) {
                    paper = strv[i].offset(LC.PAPER.length+1);
                
                } else if (strv[i].has_prefix (LC.NAME)) {
                    name = strv[i].offset(LC.NAME.length+1);
                
                } else if (strv[i].has_prefix (LC.ADDRESS)) {
                    address = strv[i].offset(LC.ADDRESS.length+1);
                
                } else if (strv[i].has_prefix (LC.TELEPHONE)) {
                    telephone = strv[i].offset(LC.TELEPHONE.length+1);
                
                } else if (strv[i].has_prefix (LC.MEASUREMENT)) {
                    measurement = strv[i].offset(LC.MEASUREMENT.length+1);

                } else if (strv[i].has_prefix (LC.IDENTIFICATION)) {
                    identification = strv[i].offset(LC.IDENTIFICATION.length+1);

                } else if (strv[i].has_prefix (LC.MESSAGES)) {
                    messages = strv[i].offset(LC.MESSAGES.length+1);

                }
                message(strv[i]);
            }

            if (lang == null) {
                lang = Intl.setlocale (LocaleCategory.MESSAGES, null);
            }

            if (messages == null) {
                messages = lang;
            }

            if (time == null) {
                time = lang;
            }

            //system_language = messages;
            //system_region = time;

            //update_language_label ();
        }
    }

	static LocaleManager? instance = null;

	public static LocaleManager init () {
		if (instance == null) {
			instance = new LocaleManager ();
		}
		return instance;
	}
}