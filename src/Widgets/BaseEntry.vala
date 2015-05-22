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

    public bool selected = false;
    public string locale {get; set;}
    public string region = "";
    public string country = "";

    public Gtk.Grid left_grid;
    public Gtk.Grid right_grid;
    public Gtk.Box settings_grid;
    private Gtk.Revealer settings_revealer;

    public BaseEntry () {

        var event_box = new Gtk.EventBox ();
        var box = new Gtk.Grid ();
        box.margin = 10;
        box.column_spacing = 6;

        var inner_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        inner_grid.homogeneous = true;

        left_grid = new Gtk.Grid ();
        left_grid.column_spacing = 6;
        left_grid.hexpand = true;
        inner_grid.pack_start (left_grid, true, true);

        right_grid = new Gtk.Grid ();
        right_grid.column_spacing = 6;
        right_grid.hexpand = true;
        inner_grid.pack_start (right_grid, true, true);

        box.attach (inner_grid, 0, 0, 1, 1);
        settings_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        settings_grid.halign = Gtk.Align.END;

        settings_revealer = new Gtk.Revealer ();
        settings_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        settings_revealer.add (settings_grid);
        settings_revealer.show_all ();
        settings_revealer.set_reveal_child (false);

        event_box.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        event_box.enter_notify_event.connect ((event) => {
            settings_revealer.set_reveal_child (true);
            return false;
        });

        event_box.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR)
                return false;

            settings_revealer.set_reveal_child (false);
            return false;
        });

        box.attach (settings_revealer, 1, 0, 1, 1);
        event_box.add (box);
        add (event_box);

        box.show_all ();

    }
}
