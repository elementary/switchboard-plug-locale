/* Copyright 2015 Switchboard Locale Plug Developers
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
    public class Preview : Gtk.Grid {
        LocaleManager lm;
        Gtk.Label first_line;
        Gtk.Label second_line;

        public Preview () {
            this.row_spacing = 10;
            this.margin_top = 10;
            this.margin_bottom = 20;

            lm = LocaleManager.get_default ();

            first_line = new Gtk.Label ("");
            second_line = new Gtk.Label ("");

            first_line.set_sensitive (false);
            second_line.set_sensitive (false);

            attach (first_line, 0, 0, 1, 1);
            attach (second_line, 0, 1, 1, 1);

            this.show_all ();
        }

        public void reload_languages (string format) {
            Intl.setlocale (LocaleCategory.ALL, format);

            var date = new DateTime.now_local ();
            first_line.set_label ("%s".printf (
                date.format ("%c")
                ));

            char currency[20];
            Monetary.strfmon (currency, "%5.2n", 1234.56);

            second_line.set_label ("%s   %s   %'.2f ".printf (
                date.format("%x   %X"),
                (string) currency,
                1234.56));
        }
    }
}
