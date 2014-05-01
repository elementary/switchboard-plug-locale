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

public class BaseEntry : Gtk.ListBoxRow {

    protected Gtk.Box settings_grid;


    public bool selected = false;
    public string locale {get; set;}
    public string region = "";
    public string country = "";

    protected Gtk.Grid left_grid;
    protected Gtk.Grid right_grid;

    public BaseEntry () {
        var box = new Gtk.Grid ();
        //box.column_homogeneous = true;
        box.margin = 10;
        
        var inner_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        inner_grid.homogeneous = true;

        left_grid = new Gtk.Grid ();
        inner_grid.pack_start (left_grid, true, true);

        right_grid = new Gtk.Grid ();
        right_grid.column_homogeneous = true;
        inner_grid.pack_start (right_grid, true, true);

        box.attach (inner_grid, 0, 0, 1, 1);

        settings_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        settings_grid.halign = Gtk.Align.END;

        box.attach (settings_grid, 1, 0, 1, 1);

        add (box);

        box.show_all ();

    }
}