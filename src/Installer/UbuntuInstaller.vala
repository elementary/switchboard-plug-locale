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

public class SwitchboardPlugLocale.Installer.UbuntuInstaller : Object {
    private const string LANGUAGE_CHECKER = "/usr/bin/check-language-support";

    private AptdProxy aptd;
    private AptdTransactionProxy proxy;

    private string []? missing_packages = null;
    public bool install_cancellable { get; private set; }
    public TransactionMode transaction_mode { get; private set; }
    public string transaction_language_code { get; private set; }

    public signal void install_finished (string langcode);
    public signal void install_failed ();
    public signal void remove_finished (string langcode);
    public signal void check_missing_finished (string [] missing);
    public signal void progress_changed (int progress);

    public enum TransactionMode {
        INSTALL,
        REMOVE,
        INSTALL_MISSING,
    }

    Gee.HashMap<string, string> transactions;

    private static GLib.Once<UbuntuInstaller> instance;
    public static unowned UbuntuInstaller get_default () {
        return instance.once (() => {
            return new UbuntuInstaller ();
        });
    }

    private UbuntuInstaller () {}

    construct {
        transactions = new Gee.HashMap<string, string> ();
        aptd = new AptdProxy ();

        try {
            aptd.connect_to_aptd ();
        } catch (Error e) {
            warning ("Could not connect to APT daemon");
        }
    }

    public async void install (string language) {
        var has_permission = yield get_permission ();
        if (!has_permission) {
            return;
        }

        transaction_mode = TransactionMode.INSTALL;
        var packages = get_remaining_packages_for_language (language);
        transaction_language_code = language;

        foreach (var packet in packages) {
            message ("Packet: %s", packet);
        }

        try {
            var transaction_id = yield aptd.install_packages (packages);
            transactions.@set (transaction_id, "i-" + language);
            run_transaction (transaction_id);
        } catch (Error e) {
            warning ("Could not queue downloads: %s", e.message);
        }
    }

    public async void check_missing_languages () {
        missing_packages = yield Utils.get_missing_languages ();
        check_missing_finished (missing_packages);
    }

    public async void install_missing_languages () throws Error {
        if (missing_packages == null || missing_packages.length == 0) {
            return;
        }

        var has_permission = yield get_permission ();
        if (!has_permission) {
            return;
        }

        transaction_mode = TransactionMode.INSTALL_MISSING;

        foreach (unowned var package in missing_packages) {
            message ("will install: %s", package);
        }

        try {
            var transaction_id = yield aptd.install_packages (missing_packages);
            transactions.@set (transaction_id, "install-missing");
            run_transaction (transaction_id);
        } catch (Error e) {
            throw (e);
        }
    }

    public async void remove (string languagecode) {
        var has_permission = yield get_permission ();
        if (!has_permission) {
            return;
        }

        transaction_mode = TransactionMode.REMOVE;
        transaction_language_code = languagecode;

        var installed = get_to_remove_packages_for_language (languagecode);

        try {
            var transaction_id = yield aptd.remove_packages (installed);
            transactions.@set (transaction_id, "r-" + languagecode);
            run_transaction (transaction_id);
        } catch (Error e) {
            warning ("Could not queue deletions: %s", e.message);
        }
    }

    private static Polkit.Permission? permission = null;
    private static async bool get_permission () {
        if (permission == null) {
            try {
                permission = yield new Polkit.Permission (
                    "io.elementary.settings.locale.administration",
                    new Polkit.UnixProcess (Posix.getpid ())
                );
            } catch (Error e) {
                critical (e.message);
                return false;
            }
        }

        if (!permission.allowed) {
            try {
                yield permission.acquire_async ();
            } catch (Error e) {
                critical (e.message);
                return false;
            }
        }

        return true;
    }

    public void cancel_install () {
        if (install_cancellable) {
            warning ("cancel_install");
            try {
                proxy.cancel ();
            } catch (Error e) {
                warning ("cannot cancel installation:%s", e.message);
            }
        }
    }

    private void run_transaction (string transaction_id) {
        proxy = new AptdTransactionProxy ();
        proxy.finished.connect (() => {
            on_apt_finshed (transaction_id, true);
        });

        proxy.property_changed.connect ((prop, val) => {
            if (prop == "Progress") {
                progress_changed ((int) val.get_int32 ());
            }

            if (prop == "Cancellable") {
                install_cancellable = val.get_boolean ();
            }
        });

        try {
            proxy.connect_to_aptd (transaction_id);
            proxy.simulate ();

            proxy.run ();
        } catch (Error e) {
            on_apt_finshed (transaction_id, false);
            warning ("Could no run transaction: %s", e.message);
        }
    }

    private void on_apt_finshed (string id, bool success) {
        if (!success) {
            install_failed ();
            transactions.unset (id);
            return;
        }

        if (!transactions.has_key (id)) { //transaction already removed
            return;
        }

        var action = transactions.get (id);
        if (action == "install-missing") {
            install_finished ("");
            transactions.unset (id);
            return;
        }

        var lang = action[2:action.length];

        message ("ID %s -> %s", id, success ? "success" : "failed");

        if (action[0:1] == "i") { // install
            install_finished (lang);
        } else {
            remove_finished (lang);
        }

        transactions.unset (id);
    }

    private string[]? get_remaining_packages_for_language (string langcode) {
        string output;
        int status;

        try {
            Process.spawn_sync (null,
                {LANGUAGE_CHECKER, "-l", langcode, null},
                Environ.get (),
                SpawnFlags.SEARCH_PATH,
                null,
                out output,
                null,
                out status);
        } catch (Error e) {
            warning ("Could not get remaining language packages for %s", langcode);
        }

        return output.strip ().split (" ");
    }

    private string[] get_to_remove_packages_for_language (string language) {
        var installed = get_installed_packages_for_language (language);

        string[] multilang_packs = { "chromium-browser-l10n", "poppler-data"};
        string[]? missing_packs = get_remaining_packages_for_language (language);

        var removable = new Gee.ArrayList<string> ();
        foreach (var packet in installed) {
            if (!(packet in multilang_packs) &&
                !(packet in missing_packs) &&
                !packet.contains ("font")
            ) {
                removable.add (packet);
            }
        }

        return removable.to_array ();
    }

    private string[]? get_installed_packages_for_language (string langcode) {
        string output;
        int status;

        try {
            Process.spawn_sync (null,
                {LANGUAGE_CHECKER, "--show-installed", "-l", langcode, null},
                Environ.get (),
                SpawnFlags.SEARCH_PATH,
                null,
                out output,
                null,
                out status);
        } catch (Error e) {
            warning ("Could not get remaining language packages for %s", langcode);
        }

        return output.strip ().split (" ");
    }
}
