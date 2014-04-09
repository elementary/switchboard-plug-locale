public class InstallEntry : LanguageEntry {


	Gtk.Label action_label;


	Gtk.Image help_image;
	Gtk.Spinner spinner;

	string processing_language;

	public InstallEntry () {
		locale = "zz_ZZ";
		region = "zz";
		country = "ZZ";

		help_image = new Gtk.Image.from_icon_name ("help-info", Gtk.IconSize.BUTTON);
		spinner = new Gtk.Spinner ();

		var image = new Gtk.Image.from_icon_name ("browser-download", Gtk.IconSize.BUTTON);
		action_box.pack_start (image);

		var label = new Gtk.Label (_("Install more languages…"));
		description_box.pack_start (label);

		action_label = new Gtk.Label ("");
		settings_box.pack_start (help_image);
		settings_box.pack_start (action_label);
		settings_box.pack_start (spinner);

		show_all ();


		help_image.hide ();
		spinner.hide ();
	}

	public void install_started (string lang) {
		processing_language = lang;
		start_spinner ();
		action_label.label = "installing…";
	}


	public void install_complete () {
		action_label.set_markup("installed <b>%s</b>".printf(Gnome.Languages.get_language_from_locale (processing_language.substring (0, 2), null)));
		
		stop_spinner ();
	}

	public void remove_started (string lang) {
		processing_language = lang;
		action_label.label = "removing…";
		
		start_spinner ();

	}

	public void remove_finished () {
		action_label.set_markup ("removed <b>%s</b>".printf (Gnome.Languages.get_language_from_locale (processing_language.substring (0, 2), null)));

		
		stop_spinner ();
	}

	public void set_error (string? error) {
		action_label.set_markup("<b>%s</b>".printf("failed"));

		stop_spinner ();
	}

	void start_spinner () {
		spinner.show ();
		spinner.start ();


		help_image.hide ();
	}

	void stop_spinner () {
		spinner.stop ();
		spinner.hide ();

		help_image.show ();

		processing_language = "";

	}




}