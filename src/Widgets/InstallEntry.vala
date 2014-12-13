/***
  Copyright (C) 2011-2012 Switchboard Locale Plug Developers
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.
  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.
  You should have received a copy of the GNU General Public License along
  with this program. If not, see 
***/

public class InstallEntry : BaseEntry {


    public Gtk.Label label;

    Gtk.Spinner spinner;
    Gtk.Image image;

    private const string STYLE = """

        GtkListBoxRow.list-row {
            background-image: none;
            background-color: #fff;
            border-radius: 5px;
            border: 1px solid #ccc;
        }

    """;

    public InstallEntry () {

        var css_provider = new Gtk.CssProvider ();
        try {
            css_provider.load_from_data (STYLE, STYLE.length);
        } catch (Error e) {
            warning ("loading css: %s", e.message);
        }          
        get_style_context ().add_provider (css_provider, -1);

        locale = "zz_ZZ";
        region = "zz";
        country = "ZZ";

        spinner = new Gtk.Spinner ();
        spinner.margin_end = 3;

        image = new Gtk.Image.from_icon_name ("browser-download", Gtk.IconSize.BUTTON);
        image.halign = Gtk.Align.START;
        image.valign = Gtk.Align.START;
        image.margin_end = 3;
        left_grid.attach (spinner, 0, 0, 1, 1);
        left_grid.attach (image, 0, 0, 1, 1);

        label = new Gtk.Label (_("Install more languages…"));
        label.halign = Gtk.Align.START;

        left_grid.attach (label, 1, 0, 2, 1);

        show_all ();
        spinner.hide ();
    }

    public void install_started () {

        start_spinner ();
    }


    public void install_complete () {

        stop_spinner ();
    }


    void start_spinner () {

        spinner.show ();
        image.hide ();
        spinner.start ();

    }

    void stop_spinner () {

        spinner.stop ();
        image.show ();
        spinner.hide ();

    }

}
