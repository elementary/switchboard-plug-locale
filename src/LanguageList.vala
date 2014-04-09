public class LanguageList : Gtk.ListBox {

	Gee.HashMap<string, LocaleEntry> locales;

	InstallPopover language_popover;
	int visible_count = 0;

	LanguageInstaller li;

	InstallEntry install_entry;

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
		", 400);

		get_style_context().add_provider_for_screen (get_style_context ().get_screen (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		get_style_context().add_class ("rounded-corners");

		valign = Gtk.Align.START;
		vexpand = true;
		hexpand = false;

		locales = new Gee.HashMap<string, LocaleEntry> ();

		li = new LanguageInstaller ();
		li.install_finished.connect (on_install_finished);
		
		install_entry = new InstallEntry();
		language_popover = new InstallPopover (install_entry);
		language_popover.language_selected.connect (on_install_language);
		add (install_entry);
	
	}

	public override void row_activated (Gtk.ListBoxRow row) {
		if (row is InstallEntry) {
			language_popover.show_all ();
		} else {
			var locale = row as LocaleEntry;
			locale.check_button.set_active (true);
		}
	}

	void on_install_language (string lang) {
		install_entry.install_started ();
		li.install (lang);
		
	}

	void on_install_finished () {
		install_entry.install_complete ();
	}

	bool filter_func (Gtk.ListBoxRow row) {
		if (visible_count >= 5) {
			//return false;
		}

		visible_count++;
		return true;
	}

	public void add_locale (string locale) {
		var l_entry = new LocaleEntry(locale);

		l_entry.language_changed.connect (on_language_changed);
		l_entry.format_changed.connect (on_format_changed);
		l_entry.input_changed.connect (on_input_changed);
		l_entry.deletion_requested.connect (on_deletion_requested);

		add (l_entry);
		show_all();
	}

	void on_deletion_requested (string locale) {
		li.remove (locale);
	}

	void on_language_changed (string lang) {
		@foreach ((row) => {
			if (row is InstallEntry) {
				return;
			}

			var locale = row as LocaleEntry;

			// uncheck other languages
			if (locale.locale == lang) {
				locale.check_button.set_active (true);
			} else {
				locale.check_button.set_active (false);

			}

		});
		
	}

	void on_format_changed (string lang) {
		@foreach ((row) => {
			if (row is InstallEntry) {
				return;
			}

			var locale = row as LocaleEntry;

			// uncheck other languages
			if (locale.locale != lang) {
				locale.format_button.get_style_context ().add_class ("insensitve");
				//locale.format_button.set_active (false);
			} else {
				locale.format_button.get_style_context ().remove_class ("insensitve");

			}

		});
	}

	void on_input_changed (string lang) {
		@foreach ((row) => {
			if (row is InstallEntry) {
				return;
			}

			var locale = row as LocaleEntry;

			// uncheck other languages
			if (locale.locale.substring (0,2) != lang.substring (0,2)) {
				locale.input_button.get_style_context ().add_class ("insensitve");
				//locale.format_button.set_active (false);
			} else {
				locale.input_button.get_style_context ().remove_class ("insensitve");

			}

		});
	}

	void on_set_region (string region) {
		var lm = LocaleManager.init ();
		lm.set_user_location (region);
	}

	int sort_func (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
		var first = row1 as LanguageEntry;
		var second = row2 as LanguageEntry;
		var diff = (int) (first.locale.collate(second.locale) );
		return diff;
	}

	void header_func (Gtk.ListBoxRow? row, Gtk.ListBoxRow? before) {
		if (before != null) {
			row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

		}
	}
}