public class InstallEntry : BaseEntry {


    public Gtk.Label label;

    Gtk.Spinner spinner;


    public InstallEntry () {
        locale = "zz_ZZ";
        region = "zz";
        country = "ZZ";

        spinner = new Gtk.Spinner ();

        var image = new Gtk.Image.from_icon_name ("browser-download", Gtk.IconSize.BUTTON);
        image.halign = Gtk.Align.START;
        left_box.pack_start (image, false, false);

        label = new Gtk.Label (_("Install more languages…"));
        label.halign = Gtk.Align.START;

        left_box.pack_start (label);


        show_all ();
        spinner.hide ();
    }

    public void install_started (string lang) {

        start_spinner ();
    }


    public void install_complete () {

        stop_spinner ();
    }


    void start_spinner () {

        spinner.show ();
        spinner.start ();

    }

    void stop_spinner () {

        spinner.stop ();
        spinner.hide ();

    }




}