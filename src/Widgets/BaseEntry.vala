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
        box.margin = 10;
        
        var inner_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        inner_box.homogeneous = true;

        left_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        inner_box.pack_start (left_box, true, true);

        right_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        right_box.homogeneous = true;
        inner_box.pack_start (right_box, true, true);

        box.pack_start (inner_box, true, true);

        settings_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        settings_box.halign = Gtk.Align.END;

        box.pack_end (settings_box, false, false);

        add (box);

        box.show_all ();

    }
}