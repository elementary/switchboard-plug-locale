public class LocaleEntry : LanguageEntry {

	string region;
	string country;

	Gtk.ToggleButton language_button;
	Gtk.ToggleButton time_button;

	Gtk.Label country_label;
	Gtk.Label region_label;

	public Gtk.CheckButton check_button;

	public signal void set_region (string region);

	public LocaleEntry (string _locale) {
		locale = _locale;

		country = Gnome.Languages.get_country_from_locale (locale, null);
		region = Gnome.Languages.get_language_from_code (locale.substring (0, 2), null);

		check_button = new Gtk.CheckButton ();

		action_box.pack_start (check_button, false, false);

		country_label = new Gtk.Label (country);
		country_label.halign = Gtk.Align.START;

		region_label = new Gtk.Label (region);
		region_label.halign = Gtk.Align.START;

		region_label.set_markup ("<b>%s</b>".printf(region));


		description_box.pack_start (region_label);
		description_box.pack_start (country_label);

		var time_image = new Gtk.Image.from_icon_name ("input-keyboard-symbolic", Gtk.IconSize.MENU);
		var input_image = new Gtk.Image.from_icon_name ("format-justify-fill-symbolic", Gtk.IconSize.MENU);

		
		language_button = new Gtk.ToggleButton();
		language_button.set_image (input_image);
		language_button.sensitive = true;
		language_button.clicked.connect (() => {
			LocaleManager.init ().set_user_language (locale);
		});

		time_button = new Gtk.ToggleButton();
		time_button.set_image (time_image);
		time_button.sensitive = true;
		time_button.clicked.connect (() => {
			LocaleManager.init ().set_user_location (locale);
		});

		settings_box.pack_start (language_button);
		settings_box.pack_start (time_button);
	}
}