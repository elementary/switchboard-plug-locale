/* Copyright 2011-2017 elementary LLC. (https://elementary.io)
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

namespace SwitchboardPlugLocale.Widgets {
    public class InstallInfoBar : Gtk.InfoBar {
        public signal void cancel_clicked ();

        public bool is_cancellable {
            set {
                cancel_button.sensitive = value;
            }
        }

        public int progress {
            set {
                if (value >= 100) {
                    hide ();
                } else {
                    show ();
                }
                progress_bar.fraction = value / 100.0;
            }
        }

        public Installer.UbuntuInstaller.TransactionMode transaction_mode {
            set {
                switch (value) {
                    case Installer.UbuntuInstaller.TransactionMode.INSTALL:
                        label.label = _("Installing language");
                        break;
                    case Installer.UbuntuInstaller.TransactionMode.REMOVE:
                        label.label = _("Removing language");
                        break;
                    case Installer.UbuntuInstaller.TransactionMode.INSTALL_MISSING:
                        label.label = _("Installing missing language");
                        break;
                }
            }
        }

        private Gtk.ProgressBar progress_bar;
        private Gtk.Label label;
        private Gtk.Button cancel_button;

        construct {
            message_type = Gtk.MessageType.INFO;

            label = new Gtk.Label (null);

            progress_bar = new Gtk.ProgressBar ();
            progress_bar.valign = Gtk.Align.CENTER;

            cancel_button = new Gtk.Button.with_label (_("Cancel"));
            cancel_button.clicked.connect (() => {
                hide ();
                cancel_clicked ();
            });

            var box = (Gtk.Box) get_content_area ();
            box.pack_start (label, false);
            box.pack_end (cancel_button, false);
            box.pack_end (progress_bar, false);
            box.show_all ();
        }
    }
}
