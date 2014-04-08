public class LanguageList : Gtk.ListBox {

	Gee.HashMap<string, LocaleEntry> locales;

	InstallPopover language_popover;
	int visible_count = 0;

	public LanguageList () {
		set_activate_on_single_click(true);
		set_sort_func (sort_func);
		set_selection_mode (Gtk.SelectionMode.NONE);
		set_header_func (header_func);
		set_filter_func (filter_func);

		var provider = new Gtk.CssProvider();
		provider.load_from_data ("
			.rounded-corners {
    			/*background-color: #aabbcc;*/
    			border-radius: 5px;

   
			}
		", 400);

		get_style_context().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		get_style_context().add_class ("rounded-corners");

		valign = Gtk.Align.START;
		vexpand = true;
		hexpand = false;

		locales = new Gee.HashMap<string, LocaleEntry> ();


		
		var install_entry = new InstallEntry();
		language_popover = new InstallPopover (install_entry);
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

	bool filter_func (Gtk.ListBoxRow row) {
		if (visible_count >= 5) {
			return false;
		}

		visible_count++;
		return true;
	}

	public void add_locale (string locale) {
		var l_entry = new LocaleEntry(locale);
		l_entry.set_region.connect (on_set_region);
		add (l_entry);
		show_all();
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