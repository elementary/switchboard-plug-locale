public class LanguageList : Gtk.ListBox {

	Gee.HashMap<string, LanguageEntry> languages;

	InstallPopover language_popover;
	int visible_count = 0;

	LanguageInstaller li;

	InstallEntry install_entry;

	string processing_language = "";

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

		li = new LanguageInstaller ();
		li.install_finished.connect (on_install_finished);
		li.remove_finished.connect (on_remove_finished);
		
		install_entry = new InstallEntry();
		language_popover = new InstallPopover (install_entry);
		language_popover.language_selected.connect (on_install_language);
		add (install_entry);
	
	}

	public void reload_languages () {
		var langs = Utils.get_installed_languages ();

        foreach (var lang in langs) {
        	message("Language: %s", lang);
            add_locale (lang);
            
        }
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

		var l_entry = new LanguageEntry(locale);

		languages.@set (locale, l_entry);

		l_entry.language_changed.connect (on_language_changed);
		l_entry.format_changed.connect (on_format_changed);
		l_entry.input_changed.connect (on_input_changed);
		l_entry.deletion_requested.connect (on_deletion_requested);

		add (l_entry);
		l_entry.show_all ();
	}



	void on_language_changed (UpdateType type, string lang) {

		message ("Language changed to: %s", lang);
		@foreach ((row) => {
			if (row is InstallEntry) {
				return;
			}

			var locale = row as LanguageEntry;

			// uncheck other languages
			if (locale.locale == lang) {
				//locale.check_button.set_active (true);
			} else {
				//locale.check_button.set_active (false);

			}

		});
		
	}

	void on_format_changed (string lang) {
		@foreach ((row) => {
			if (row is InstallEntry) {
				return;
			}

			var locale = row as LanguageEntry;

			// uncheck other languages
			if (locale.locale != lang) {
				//locale.format_button.get_style_context ().add_class ("insensitve");
				//locale.format_button.set_active (false);
			} else {
				//locale.format_button.get_style_context ().remove_class ("insensitve");

			}

		});
	}

	void on_input_changed (string lang) {
		@foreach ((row) => {
			if (row is InstallEntry) {
				return;
			}

			var locale = row as LanguageEntry;

			// uncheck other languages
			if (locale.locale.substring (0,2) != lang.substring (0,2)) {
				//locale.input_button.get_style_context ().add_class ("insensitve");
				//locale.format_button.set_active (false);
			} else {
				//locale.input_button.get_style_context ().remove_class ("insensitve");

			}

		});
	}

	void on_set_region (string region) {
		var lm = LocaleManager.init ();
		lm.set_user_location (region);
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