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
    public class LocaleView : Granite.Widgets.ThinPaned {
        private weak Plug               plug;
        private Gtk.Box                 sidebar;
        private Gtk.ToolButton          add_button;
        private Gtk.ToolButton          remove_button;

        public LanguageListBox          list_box;
        public LocaleSetting            locale_setting;

       LocaleManager lm;

        public LocaleView (Plug plug) {
            this.plug = plug;
            lm = LocaleManager.get_default ();
            build_ui ();
        }

        private void build_ui () {
            list_box = new LanguageListBox ();
            list_box.settings_changed.connect (() => {
                var regions = Utils.get_regions (list_box.get_selected_language_code ());

                debug ("reloading Settings widget for language '%s'".printf (list_box.get_selected_language_code ()));
                locale_setting.reload_regions (list_box.get_selected_language_code (), regions);
                locale_setting.reload_labels (list_box.get_selected_language_code ());

                if (remove_button != null) {
                    if (list_box.get_selected_language_code () == lm.get_user_language ().slice (0, 2))
                        remove_button.set_sensitive (false);
                    else if (Utils.get_permission ().allowed)
                        remove_button.set_sensitive (true);
                }
            });

            sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            var scroll = new Gtk.ScrolledWindow (null, null);
            scroll.add (list_box);
            scroll.expand = true;
            sidebar.pack_start (scroll, true, true);

            add_button = new Gtk.ToolButton (null, "add");
            add_button.set_icon_name ("list-add-symbolic");
            add_button.set_tooltip_text (_("Install language"));
            add_button.set_sensitive (false);
            add_button.clicked.connect (() => {
                var popover = new Widgets.InstallPopover (add_button);
                popover.show_all ();
                popover.language_selected.connect (plug.on_install_language);
            });

            remove_button = new Gtk.ToolButton (null, "remove");
            remove_button.set_icon_name ("list-remove-symbolic");
            remove_button.set_tooltip_text (_("Remove language"));
            remove_button.set_sensitive (false);
            remove_button.clicked.connect (() => {
                make_sensitive (false);
                plug.installer.remove (list_box.get_selected_language_code ());
            });

            var keyboard_button = new Gtk.ToolButton (null, "keyboard");
            keyboard_button.set_icon_name ("input-keyboard-symbolic");
            keyboard_button.set_tooltip_text (_("Switch to keyboard settings"));
            keyboard_button.clicked.connect (() => {
                var command = new Granite.Services.SimpleCommand (
                            Environment.get_home_dir (),
                            "/usr/bin/switchboard -o hardware-pantheon-keyboard");
                command.run ();
            });

            var tbar = new Gtk.Toolbar ();
            tbar.set_style (Gtk.ToolbarStyle.ICONS);
            tbar.set_icon_size (Gtk.IconSize.SMALL_TOOLBAR);
            tbar.set_show_arrow (false);
            tbar.hexpand = true;
            tbar.insert (add_button, -1);
            tbar.insert (remove_button, -1);

            var separator = new Gtk.SeparatorToolItem ();
            separator.set_draw (false);
            separator.set_expand (true);
            tbar.insert (separator, -1);

            tbar.insert (keyboard_button, -1);

            scroll.get_style_context().set_junction_sides(Gtk.JunctionSides.BOTTOM);
            tbar.get_style_context().add_class(Gtk.STYLE_CLASS_INLINE_TOOLBAR);
            tbar.get_style_context().set_junction_sides(Gtk.JunctionSides.TOP);

            locale_setting = new LocaleSetting ();
            locale_setting.margin_top = 50;
            locale_setting.hexpand = true;
            locale_setting.settings_changed.connect (() => {
                plug.infobar.no_show_all = false;
                plug.infobar.show_all ();
            });

            sidebar.pack_start (tbar, false, false);

            pack1 (sidebar, true, false);
            pack2 (locale_setting, true, false);

            set_position (200);

            Utils.get_permission ().notify["allowed"].connect (() => {
                if (Utils.get_permission ().allowed) {
                    add_button.set_sensitive (true);
                    if (list_box.get_selected_language_code () != lm.get_user_language ().slice (0, 2))
                        remove_button.set_sensitive (true);
                } else {
                    add_button.set_sensitive (false);
                    remove_button.set_sensitive (false);
                }
            });
            show_all ();
        }

        public void make_sensitive (bool sensitive) {
            sidebar.set_sensitive (sensitive);
            locale_setting.set_sensitive (sensitive);
        }
    }
}
