/* Copyright 2011-2019 elementary, Inc. (https://elementary.io)
*
* This program is free software: you can redistribute it
* and/or modify it under the terms of the GNU Lesser General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with this program. If not, see http://www.gnu.org/licenses/.
*/

public class SwitchboardPlugLocale.ProgressDialog : Gtk.Dialog {
    public int progress {
        set {
            if (value >= 100) {
                destroy ();
            }
            progress_bar.fraction = value / 100.0;
        }
    }

    public Installer.UbuntuInstaller installer { get; construct; }

    private Gtk.ProgressBar progress_bar;

    public ProgressDialog (Installer.UbuntuInstaller installer) {
        Object (installer: installer);
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("preferences-desktop-locale", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        var transaction_language_name = Utils.translate (installer.transaction_language_code, null);

        var primary_label = new Gtk.Label (null);
        primary_label.max_width_chars = 50;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        switch (installer.transaction_mode) {
            case Installer.UbuntuInstaller.TransactionMode.INSTALL:
                primary_label.label = _("Installing %s").printf (transaction_language_name);
                break;
            case Installer.UbuntuInstaller.TransactionMode.REMOVE:
                primary_label.label = _("Removing %s").printf (transaction_language_name);
                break;
            case Installer.UbuntuInstaller.TransactionMode.INSTALL_MISSING:
                primary_label.label = _("Installing missing language");
                break;
        }

        progress_bar = new Gtk.ProgressBar ();
        progress_bar.width_request = 300;
        progress_bar.hexpand = true;
        progress_bar.valign = Gtk.Align.START;

        var cancel_button = (Gtk.Button) add_button (_("Cancel"), 0);

        installer.bind_property ("install-cancellable", cancel_button, "sensitive");

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 6;
        grid.margin = 6;
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0);
        grid.attach (progress_bar, 1, 1);
        grid.show_all ();

        border_width = 6;
        deletable = false;
        get_content_area ().add (grid);

        cancel_button.clicked.connect (() => {
            installer.cancel_install ();
            destroy ();
        });
    }
}
