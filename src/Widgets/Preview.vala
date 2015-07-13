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
