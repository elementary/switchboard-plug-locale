public class LanguageList : Gtk.ListBox {

	Gee.HashMap<string, LanguageEntry> languages;

	InstallPopover language_popover;
	int visible_count = 0;

	UbuntuInstaller li;

	InstallEntry install_entry;

	public Gtk.RadioButton language_button = new Gtk.RadioButton (null);
	public Gtk.RadioButton format_button = new Gtk.RadioButton (null);


	Gee.HashMap<string, string?> input_sources;


	public LocaleManager lm;

	public LanguageList () {
		set_activate_on_single_click(true);
		set_sort_func (sort_func);
		set_selection_mode (Gtk.SelectionMode.NONE);
		set_header_func (header_func);
		set_filter_func (filter_func);

		get_style_context().add_class ("rounded-corners");



		valign = Gtk.Align.START;
		vexpand = true;
		hexpand = false;

		languages = new Gee.HashMap<string, LanguageEntry> ();
		languages.notify["size"].connect (on_nr_of_languages_changed);
		input_sources = new Gee.HashMap<string, string?> ();

		li = new UbuntuInstaller ();
		li.install_finished.connect (on_install_finished);
		li.remove_finished.connect (on_remove_finished);
		lm = LocaleManager. init();
		lm.loaded_user.connect (on_user_settings_loaded);
		
		install_entry = new InstallEntry();
		language_popover = new InstallPopover (install_entry.label);
		language_popover.li = li;
		language_popover.language_selected.connect (on_install_language);
		add (install_entry);

	
	}

	void on_nr_of_languages_changed () {
		if (languages.size < 2) {
			languages.foreach ((entry) => {
				entry.value.hide_delete ();
				return true;
			});
		} else {
			languages.foreach ((entry) => {
				entry.value.show_delete ();
				return true;
			});
		}
	}

	bool update_lock = false;



	void on_user_settings_loaded (string language, string format, Gee.HashMap<string, string> inputs) {

		select_language (language);
		select_format (format);
		select_inputs (inputs);
/*
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
		*/

	}

	public void reload_languages () {
		var langs = Utils.get_installed_languages ();

        foreach (var lang in langs) {
            add_locale (lang);
        }

        var locale = lm.get_user_language ();

        var entry = languages.@get (locale.substring (0, 2));

        requery_display ();


	}

	void requery_display () {

		var lang = lm.get_user_language ();
		var region = lm.get_user_format ();
		var inputs = lm.get_user_inputmaps ();

		critical ("Lang %s Format %s Input", lang, region);

		update_lock = true;

		select_language (lang);
		select_format (region);
		select_inputs (inputs);

		update_lock = false;
	}

	/*
	 * update selections
	 */

	void select_language (string language) {

		var langcode = language[0:2];

		var lang = languages.get (langcode);
		lang.set_display_region (language);

	}

	void select_format (string locale) {

		var langcode = locale[0:2];

		var lang = languages.get (langcode);
		lang.set_display_format(locale[0:5]);

	}

	void select_inputs (Gee.HashMap<string, string> map) {
		
		map.@foreach ((entry) => {
			warning ("clicking %s -> %s", entry.key, entry.value);
			input_sources.@set (entry.key, entry.value);
			var lang = languages.get (entry.key);
			lang.set_display_input (entry.value);
			return true;
		});

	}

	public override void row_activated (Gtk.ListBoxRow row) {

		if (row is InstallEntry) {
			language_popover.show_all ();
		} else {
			var locale = row as LanguageEntry;
			locale.check_button.set_active (true);
		}

	}



	void on_install_language (string lang) {
		li.install (lang);
		
	}

	void on_install_finished (string language) {
		
			reload_languages ();

	}

	void on_deletion_requested (string locale) {
		li.remove (locale);
	}

	void on_remove_finished (string langcode) {
		message("removed %s", langcode);
		var widget = languages.@get (langcode);
		remove (widget);
		languages.unset (langcode);

		if (languages.size == 1) {
			languages.@foreach ((entry) => {
				entry.value.hide_delete ();
				return true;
			});
		}

	}

	bool filter_func (Gtk.ListBoxRow row) {

		return true;

	}

	public void add_locale (string locale) {
		var language = locale.substring (0, 2);

		if (languages.has_key (language)) {
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

		if (languages.size == 1) {
			languages.@foreach ((entry) => {
				entry.value.hide_delete ();
				return true;
			});
		} else {
			languages.@foreach ((entry) => {
				entry.value.show_delete ();
				return true;
			});
		}
		
	}



	void on_language_changed (UpdateType type, string lang) {
		
		if (update_lock) {
			return;
		}

		message ("Language changed to: %s", lang);


		switch (type) {
			case UpdateType.LANGUAGE:
				lm.set_user_language (lang);
				break;
			case UpdateType.FORMAT:
				lm.set_user_format (lang+".UTF-8");
				break;
		}

			

		
	}


	void on_input_changed (string langcode, string inputcode, bool added) {
		if (update_lock) {
			return;
		}

		if (!added) {
			input_sources.@unset (langcode);
		} else {

			input_sources.@set (langcode, inputcode);
		}

		VariantBuilder builder2 = new VariantBuilder (new VariantType ("a(ss)") );		
		VariantBuilder builder = new VariantBuilder (new VariantType ("a(ss)") );		
		input_sources.@foreach((entry) => {
			message ("('%s', '%s')", "xkb", entry.value);
			builder2.add ("(ss)", entry.key, entry.value);
			builder.add ("(ss)", "xkb", entry.value);
			return true;
		});	

		var lm = LocaleManager.init ();
		lm.set_input_language (builder.end (), builder2.end ());
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