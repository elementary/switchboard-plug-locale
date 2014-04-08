public class InstallPopover : Gtk.Popover {

	Gtk.Box box;
	Gtk.SearchEntry search_entry;
	Gtk.ListBox languages_box;
	
	public InstallPopover (Gtk.Widget relative_to) {
		Object (relative_to: relative_to);
		box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);

		search_entry = new Gtk.SearchEntry ();
		box.pack_start (search_entry);

		languages_box = new Gtk.ListBox ();
		box.pack_start (languages_box);

		add (box);

	}
}