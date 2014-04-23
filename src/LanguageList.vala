public class LanguageList : Gtk.ListBox {

	Gee.HashMap<string, LanguageEntry> languages;

	InstallPopover language_popover;
	int visible_count = 0;

	LanguageInstaller li;

	InstallEntry install_entry;

	string processing_language = "";

	string? language;
	string? format;
	string? input;

	public static Gtk.RadioButton language_button = new Gtk.RadioButton (null);
	public static Gtk.RadioButton format_button = new Gtk.RadioButton (null);
	public static Gtk.RadioButton input_button = new Gtk.RadioButton (null);


	Gee.HashMap<string, string?> input_sources;


	public LocaleManager lm;

	public LanguageList () {
		set_activate_on_single_click(true);
		set_sort_func (sort_func);
		set_selection_mode (Gtk.SelectionMode.NONE);
		set_header_func (header_func);
		set_filter_func (filter_func);

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

		get_style_context().add_provider_for_screen (get_style_context ().get_screen (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		get_style_context().add_class ("rounded-corners");



		valign = Gtk.Align.START;
		vexpand = true;
		hexpand = false;

		languages = new Gee.HashMap<string, LanguageEntry> ();
		input_sources = new Gee.HashMap<string, string?> ();

		li = new LanguageInstaller ();
		li.install_finished.connect (on_install_finished);
		li.remove_finished.connect (on_remove_finished);
		lm = LocaleManager. init();
		lm.loaded_user.connect (on_user_settings_loaded);
		
		install_entry = new InstallEntry();
		language_popover = new InstallPopover (install_entry);
		language_popover.language_selected.connect (on_install_language);
		add (install_entry);

	
	}

	bool update_lock = false;

	void on_user_settings_loaded (string language, string format) {


		@foreach ((child) => {
			if (child is InstallEntry)
				return;

			var entry = child as LanguageEntry;
			message("%s",entry.langcode);
			update_lock = true;
			entry.set_display_region (language);
			entry.set_display_format (format.substring (0, 5));
			//set_display_input ("us");
			update_lock = false;
		});

	}

	public void reload_languages () {
		var langs = Utils.get_installed_languages ();

        foreach (var lang in langs) {
        	message("Language: %s", lang);
            add_locale (lang);
        }

        var locale = lm.get_user_language ();

        var entry = languages.@get (locale.substring (0, 2));
        entry.set_display_region (locale);


	}

	public override void row_activated (Gtk.ListBoxRow row) {
		if (row is InstallEntry) {
			language_popover.show_all ();
		} else {
			var locale = row as LanguageEntry;
			//locale.check_button.set_active (true);
		}
	}

	void on_install_language (string lang) {
		processing_language = lang;
		install_entry.install_started (lang);
		li.install (lang);
		
	}

	void on_install_finished (bool success, string? message) {
		
		if (success) {
			install_entry.install_complete ();
			reload_languages ();		
		} else {
			install_entry.set_error (message);
		}

		processing_language = "";


	}

	void on_deletion_requested (string locale) {
		processing_language = locale;
		install_entry.remove_started (locale);
		li.remove (locale);
	}

	void on_remove_finished () {
		install_entry.remove_finished();
		var widget = languages.@get (processing_language);
		remove (widget);
		languages.unset (processing_language);
		processing_language = "";
	}

	bool filter_func (Gtk.ListBoxRow row) {
		if (visible_count >= 5) {
			//return false;
		}

		visible_count++;
		return true;
	}

	public void add_locale (string locale) {
		var language = locale.substring (0, 2);

		if (languages.has_key (language)) {
			message ("Language %s found, adding region %s", locale, language);
			var entry = languages.@get (language);
			entry.add_region (locale);

			return;
		}

		var l_entry = new LanguageEntry(locale, this);

		languages.@set (language, l_entry);

		l_entry.language_changed.connect (on_language_changed);
		//l_entry.format_changed.connect (on_format_changed);
		l_entry.input_changed.connect (on_input_changed);
		l_entry.deletion_requested.connect (on_deletion_requested);

		add (l_entry);
		l_entry.show_all ();
	}



	void on_language_changed (UpdateType type, string lang) {
		if (update_lock) {
			return;

		}
		message ("Language changed to: %s", lang);


		switch (type) {
			case UpdateType.LANGUAGE:
				message("lang");
				var lm = LocaleManager.init ();
				lm.set_user_language (lang);
				break;
			case UpdateType.FORMAT:
				message("format");
				var lm = LocaleManager.init ();
				//lm.set_user_location (lang);
				//lm.set_user_region (lang);
				lm.set_user_format (lang+".UTF-8");
				break;
			case UpdateType.INPUT:
				message("input");
				break;
		}

			

		
	}


	void on_input_changed (string langcode, string inputcode, bool added) {
		if (!added) {
			input_sources.@unset (langcode);
		} else {

			input_sources.@set (langcode, inputcode);
		}

		VariantBuilder builder = new VariantBuilder (new VariantType ("a(ss)") );		
		input_sources.@foreach((entry) => {
			message ("('%s', '%s')", "xkb", entry.value);
			builder.add ("(ss)", "xkb", entry.value);
			return true;
		});	

		var lm = LocaleManager.init ();
		lm.set_input_language (builder.end ());
	}

	void on_set_region (string region) {
		
	}

	int sort_func (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
		var first = row1 as BaseEntry;
		var second = row2 as BaseEntry;

		var string1 = first.region + " " + first.country;
		var string2 = second.region + " " + second.country;
		var diff = (int) (string1.collate (string2) );
		return diff;
	}

	void header_func (Gtk.ListBoxRow? row, Gtk.ListBoxRow? before) {
		if (before != null) {
			row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

		}
	}
}