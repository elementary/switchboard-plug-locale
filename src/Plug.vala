/* Copyright 2011-2015 Switchboard Locale Plug Developers
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

namespace SwitchboardPlugLocale {
    public class Plug : Switchboard.Plug {
        private Widgets.LocaleView view;

        public Plug () {
            GLib.Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
            GLib.Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");

            var settings = new Gee.TreeMap<string, string?> (null, null);
            settings.set ("language", null);

            Object (category: Category.PERSONAL,
                    code_name: "io.elementary.settings.locale",
                    display_name: _("Language & Region"),
                    description: _("Manage languages, and configure region and format"),
                    icon: "preferences-desktop-locale",
                    supported_settings: settings);
        }

        public override Gtk.Widget get_widget () {
            if (view == null) {
                Utils.init ();
                view = new Widgets.LocaleView ();
            }

            return view;
        }

        public override void shown () {

        }

        public override void hidden () {

        }

        public override void search_callback (string location) {

        }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            var search_results = new Gee.TreeMap<string, string> (
                (GLib.CompareDataFunc<string>)strcmp,
                (Gee.EqualDataFunc<string>)str_equal
            );
            search_results.set ("%s → %s".printf (display_name, _("Region")), "");
            search_results.set ("%s → %s".printf (display_name, _("Formats")), "");
            search_results.set ("%s → %s".printf (display_name, _("Temperature")), "");
            return search_results;
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Locale plug");
    var plug = new SwitchboardPlugLocale.Plug ();
    return plug;
}
