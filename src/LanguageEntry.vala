public class LanguageEntry : Gtk.ListBoxRow {

	protected Gtk.Box box;
	protected Gtk.Box action_box;
	protected Gtk.Box description_box;
	protected Gtk.Box settings_box;

	public bool selected = false;
	public string locale {get; set;}


	public LanguageEntry () {
		box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
		box.margin = 12;

		action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		box.pack_start (action_box, false, false);

		description_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
		box.pack_start (description_box, false, false);

		var fix_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		settings_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
		settings_box.halign = Gtk.Align.END;

		fix_box.pack_start (settings_box, true, false);
		box.pack_end (fix_box, false, false);

		add (box);

		box.show_all ();

	}
}