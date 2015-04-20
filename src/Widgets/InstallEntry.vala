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

public class InstallEntry : BaseEntry {
    public signal void cancel_clicked ();
    public signal void on_install_language (string lang);

    Gtk.Label label;
    Gtk.Label label2;
    Gtk.ProgressBar progress;
    Gtk.Button cancel_button;
    Gtk.Spinner spinner;
    Gtk.Image image;
    Gtk.Stack content_stack;
    InstallPopover language_popover;
    bool installing = false;

    private const string STYLE = """

        GtkListBoxRow.list-row {
            background-image: none;
            background-color: #fff;
            border-radius: 5px;
            border: 1px solid #ccc;
        }

    """;

    public InstallEntry () {
        base ();
        right_grid.destroy ();
        var css_provider = new Gtk.CssProvider ();
        try {
            css_provider.load_from_data (STYLE, STYLE.length);
        } catch (Error e) {
            warning ("loading css: %s", e.message);
        }          
        get_style_context ().add_provider (css_provider, -1);

        locale = "zz_ZZ";
        region = "zz";
        country = "ZZ";

        /* Addition Grid */
        image = new Gtk.Image.from_icon_name ("browser-download", Gtk.IconSize.BUTTON);
        image.halign = Gtk.Align.START;
        image.valign = Gtk.Align.START;

        label = new Gtk.Label (_("Install more languages…"));
        label.halign = Gtk.Align.START;
        label.hexpand = true;

        var add_content = new Gtk.Grid ();
        add_content.row_spacing = 6;
        add_content.valign = Gtk.Align.CENTER;
        add_content.column_spacing = 12;
        add_content.attach (image, 0, 0, 1, 1);
        add_content.attach (label, 1, 0, 1, 1);

        /* Installation Grid */
        spinner = new Gtk.Spinner ();
        progress = new Gtk.ProgressBar ();

        label2 = new Gtk.Label (_("installing language"));
        label2.halign = Gtk.Align.START;
        label2.hexpand = true;

        var install_content = new Gtk.Grid ();
        install_content.row_spacing = 6;
        install_content.column_spacing = 12;
        install_content.attach (spinner, 0, 0, 1, 2);
        install_content.attach (label2, 1, 0, 1, 1);
        install_content.attach (progress, 1, 1, 1, 1);

        cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.clicked.connect (() => {
            install_complete ();
            cancel_clicked ();
        });
        settings_grid.add (cancel_button);

        content_stack = new Gtk.Stack ();
        content_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        content_stack.add_named (add_content, "normal");
        content_stack.add_named (install_content, "install");
        left_grid.add (content_stack);

        language_popover = new InstallPopover (label);
        language_popover.language_selected.connect ((lang) => on_install_language (lang));

        show_all ();
        spinner.hide ();
        cancel_button.hide ();
    }

    public void do_activate () {
        if (installing == false) {
            language_popover.show_all ();
        }
    }

    public void install_started () {
        installing = true;
        content_stack.set_visible_child_name ("install");
        set_cancellable (true);
        cancel_button.show ();
        spinner.start ();
    }

    public void install_complete () {
        installing = false;
        spinner.stop ();
        cancel_button.hide ();
        content_stack.set_visible_child_name ("normal");
    }

    public void set_transaction_mode (UbuntuInstaller.TransactionMode transaction_mode) {
        switch (transaction_mode) {
            case UbuntuInstaller.TransactionMode.INSTALL:
                label2.label = _("installing language");
                break;
            case UbuntuInstaller.TransactionMode.REMOVE:
                label2.label = _("removing language");
                break;
            case UbuntuInstaller.TransactionMode.INSTALL_MISSING:
                label2.label = _("installing missing language");
                break;
        }
    }

    public void set_cancellable (bool cancellable) {
        cancel_button.sensitive = cancellable;
    }

    public void set_progress (int progress) {
        this.progress.fraction = progress / 100.0;
    }
}
