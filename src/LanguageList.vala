public class LanguageList : Gtk.ListBox {

	Gee.HashMap<string, LocaleEntry> locales;

	public LanguageList () {
		set_sort_func (sort_func);
		set_selection_mode (Gtk.SelectionMode.NONE);
		set_header_func (header_func);

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
		add (install_entry);
	
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