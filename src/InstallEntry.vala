public class InstallEntry : LanguageEntry {

	public InstallEntry () {
		locale = "zz_ZZ";

		var image = new Gtk.Image.from_icon_name ("browser-download", Gtk.IconSize.BUTTON);
		action_box.pack_start (image);

		var label = new Gtk.Label (_("Install more languages…"));
		description_box.pack_start (label);

	}
}