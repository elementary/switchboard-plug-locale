/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 */

public class SwitchboardPlugLocale.ProgressDialog : Granite.Dialog {
    construct {
        var image = new Gtk.Image.from_icon_name ("preferences-desktop-locale") {
            pixel_size = 48,
            valign = START
        };

        unowned var installer = Installer.UbuntuInstaller.get_default ();

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

        var progress_bar = new Gtk.ProgressBar () {
            hexpand = true,
            valign = START,
            width_request = 300
        };

        var cancel_button = (Gtk.Button) add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6
        };
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0);
        grid.attach (progress_bar, 1, 1);

        modal = true;
        resizable = false;
        get_content_area ().append (grid);

        installer.bind_property ("install-cancellable", cancel_button, "sensitive");
        installer.progress_changed.connect ((value) => {
            if (value >= 100) {
                response (Gtk.ResponseType.DELETE_EVENT);
            }
            progress_bar.fraction = value / 100.0;
        });

        response.connect ((response) => {
            if (response == Gtk.ResponseType.CANCEL) {
                installer.cancel_install ();
            }

            close ();
        });
    }
}
