public class BaseEntry : Gtk.ListBoxRow {

	Gtk.Box box;

	protected Gtk.Box settings_box;


	public bool selected = false;
	public string locale {get; set;}
	public string region = "";
	public string country = "";

	protected Gtk.Box left_box;
	protected Gtk.Box right_box;

	public BaseEntry () {
		box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
		box.margin = 12;
		
		var inner_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
		inner_box.homogeneous = true;
/*
		action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		action_box.get_style_context ().add_class ("bg1");
		//box.pack_start (action_box, false, false);
*/

/*

*/
		left_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
		//left_box.get_style_context ().add_class ("bg1");
		inner_box.pack_start (left_box, true, true);

		right_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
		right_box.homogeneous = true;
		//right_box.get_style_context ().add_class ("bg2");
		inner_box.pack_start (right_box, true, true);

		box.pack_start (inner_box, true, true);

		var fix_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		settings_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
		settings_box.halign = Gtk.Align.END;

		fix_box.pack_start (settings_box, true, false);
		//fix_box.get_style_context ().add_class ("bg4");
		box.pack_end (fix_box, false, false);


		add (box);

		box.show_all ();

	}
}