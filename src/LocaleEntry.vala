public class LocaleEntry : LanguageEntry {



	public Gtk.ToggleButton input_button;
	public Gtk.ToggleButton format_button;
	public Gtk.Button delete_button;
	public Gtk.CheckButton check_button;

	Gtk.Label country_label;
	Gtk.Label region_label;



	public signal void set_region (string region);

	public signal void language_changed (string region);
	public signal void format_changed (string region);
	public signal void input_changed (string region);
	public signal void deletion_requested (string region);

	public LocaleEntry (string _locale) {
		locale = _locale;

		country = Gnome.Languages.get_country_from_locale (locale, null);
		region = Gnome.Languages.get_language_from_code (locale.substring (0, 2), null);

		check_button = new Gtk.CheckButton ();
		check_button.toggled.connect (() => {
			if (check_button.active) {
				language_changed (locale);

			}
		});

		action_box.pack_start (check_button, false, false);

		country_label = new Gtk.Label (Utils.get_default ().translate_country (country));
		country_label.halign = Gtk.Align.START;

		region_label = new Gtk.Label (Utils.get_default ().translate_language (region));
		region_label.halign = Gtk.Align.START;

		region_label.set_markup ("<b>%s</b>".printf(region_label.label));


		description_box.pack_start (region_label);
		description_box.pack_start (country_label);

		var input_image = new Gtk.Image.from_icon_name ("input-keyboard-symbolic", Gtk.IconSize.MENU);
		var format_image = new Gtk.Image.from_icon_name ("format-justify-fill-symbolic", Gtk.IconSize.MENU);
		var delete_image = new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.MENU);


		
		input_button = new Gtk.ToggleButton();
		input_button.get_style_context ().remove_class ("button");
		input_button.get_style_context ().add_class ("insenstive");
		input_button.set_image (input_image);
		input_button.sensitive = true;
		input_button.clicked.connect (() => {
			input_changed (locale);
		});

		format_button = new Gtk.ToggleButton();
		format_button.get_style_context ().remove_class ("button");
		format_button.get_style_context ().add_class ("insenstive");
		format_button.set_image (format_image);
		format_button.sensitive = true;
		format_button.clicked.connect (() => {
			format_changed (locale);
		});

		delete_button = new Gtk.ToggleButton();
		delete_button.get_style_context ().remove_class ("button");
		delete_button.set_image (delete_image);
		delete_button.sensitive = true;
		delete_button.clicked.connect (() => {
			deletion_requested (locale);
		});

		settings_box.pack_start (format_button);
		settings_box.pack_start (input_button);
		settings_box.pack_start (delete_button);

	}
}