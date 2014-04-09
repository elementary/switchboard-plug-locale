public class InstallEntry : LanguageEntry {


	Gtk.Label action_label;

	public InstallEntry () {
		locale = "zz_ZZ";

		var image = new Gtk.Image.from_icon_name ("browser-download", Gtk.IconSize.BUTTON);
		action_box.pack_start (image);

		var label = new Gtk.Label (_("Install more languages…"));
		description_box.pack_start (label);

		action_label = new Gtk.Label ("test");
		settings_box.pack_start (action_label);

	}

	public void install_complete () {
		action_label.label = "finished";
		show_all ();
	}

	public void install_started () {
		action_label.label = "installing";
		show_all ();
	}
}