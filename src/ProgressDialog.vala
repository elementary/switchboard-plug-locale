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

public class SwitchboardPlugLocale.ProgressDialog : Granite.Dialog {
    public int progress {
        set {
            if (value >= 100) {
                response (Gtk.ResponseType.DELETE_EVENT);
            }
            progress_bar.fraction = value / 100.0;
        }
    }

    private Gtk.ProgressBar progress_bar;

    construct {
        var image = new Gtk.Image.from_icon_name ("preferences-desktop-locale") {
            pixel_size = 48,
            valign = START
        };

        unowned Installer.UbuntuInstaller installer = Installer.UbuntuInstaller.get_default ();

        var transaction_language_name = Utils.translate (installer.transaction_language_code, null);

        var primary_label = new Gtk.Label (null) {
            max_width_chars = 50,
            wrap = true,
            xalign = 0
        };
        primary_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        switch (installer.transaction_mode) {
            case INSTALL:
                primary_label.label = _("Installing %s").printf (transaction_language_name);
                break;
            case REMOVE:
                primary_label.label = _("Removing %s").printf (transaction_language_name);
                break;
            case INSTALL_MISSING:
                primary_label.label = _("Installing missing language");
                break;
        }

        progress_bar = new Gtk.ProgressBar () {
            hexpand = true,
            valign = START,
            width_request = 300
        };

        var cancel_button = (Gtk.Button) add_button (_("Cancel"), 0);

        installer.bind_property ("install-cancellable", cancel_button, "sensitive");

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6
        };
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0);
        grid.attach (progress_bar, 1, 1);

        resizable = false;
        get_content_area ().append (grid);

        cancel_button.clicked.connect (() => {
            installer.cancel_install ();
            response (Gtk.ResponseType.CANCEL);
        });
    }
}
