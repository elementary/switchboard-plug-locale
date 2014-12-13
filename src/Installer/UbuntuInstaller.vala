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

public class UbuntuInstaller : Object {

    static const string LANGUAGE_CHECKER = "/usr/bin/check-language-support";
    static const string LOCALES_INSTALLER = "/usr/share/locales/install-language-pack";
    static const string LOCALES_REMOVER = "/usr/share/locales/install-language-pack";

    AptdProxy aptd;
    AptdTransactionProxy proxy;

    string[]? missing_packages = null;
    public bool install_cancellable;
    public TransactionMode transaction_mode;

    public signal void install_finished (string langcode);
    public signal void remove_finished (string langcode);
    public signal void check_missing_finished (string[] missing);
    public signal void progress_changed (int progress);

    public enum TransactionMode {
        INSTALL,
        REMOVE,
        INSTALL_MISSING,
    }

    Gee.HashMap<string, string> transactions;

    public UbuntuInstaller () {

        transactions = new Gee.HashMap<string, string> ();
        aptd = new AptdProxy ();

        try {
            aptd.connect_to_aptd ();
        } catch (Error e) {
            warning ("Could not connect to APT daemon");
        }
        
    }

    public void install (string language) {
        transaction_mode = TransactionMode.INSTALL;
        var packages = get_remaining_packages_for_language (language);

        foreach (var packet in packages) {
            message("Packet: %s", packet);
        }

        aptd.install_packages.begin (packages, (obj, res) => {

            try {
                var transaction_id = aptd.install_packages.end (res);
                transactions.@set (transaction_id, "i- " + language);
                run_transaction (transaction_id);
            } catch (Error e) {
                warning ("Could not queue downloads: %s", e.message);
            }


        });

    }

    public void install_packages (string[] packages) {
        foreach (var packet in packages) {
            message("will install: %s", packet);
        }

        aptd.install_packages.begin (packages, (obj, res) => {

            try {
                var transaction_id = aptd.install_packages.end (res);
                transactions.@set (transaction_id, "install-missing");
                run_transaction (transaction_id);
            } catch (Error e) {
                warning ("Could not queue downloads: %s", e.message);
            }
        });

    }

    public void check_missing_languages () {
        Utils.get_missing_languages.begin ((obj, res) => {
                try {
                    missing_packages = Utils.get_missing_languages.end (res);

                    if (missing_packages != null)
                        check_missing_finished (missing_packages);
                } catch (Error e){
                    warning ("cant parse missing language:%s", e.message);
                }
        });

    }

    public void install_missing_languages () {
        if (missing_packages == null || missing_packages.length == 0)
            return;
        transaction_mode = TransactionMode.INSTALL_MISSING;

        install_packages (missing_packages);
    }

    public void remove (string languagecode) {
        transaction_mode = TransactionMode.REMOVE;

        var installed = get_to_remove_packages_for_language (languagecode);


        aptd.remove_packages.begin (installed, (obj, res) => {

            try {
                var transaction_id = aptd.remove_packages.end (res);
                transactions.@set (transaction_id, "r-"+languagecode);
                run_transaction (transaction_id);
            } catch (Error e) {
                warning ("Could not queue deletions: %s", e.message);
            }

        });

    }

    public void cancel_install () {
        if (install_cancellable){
            warning ("cancel_install");
            try {
                proxy.cancel ();
            } catch (Error e) {
                warning ("cannot cancel installation:%s", e.message);
            }
        }
    }

    void run_transaction (string transaction_id) {

        proxy = new AptdTransactionProxy ();
        proxy.finished.connect (() => {
            on_apt_finshed (transaction_id, true);
        });

        proxy.property_changed.connect ((prop, val) => {
            if (prop == "Progress")
                progress_changed ((int)val.get_int32 ());
            if (prop=="Cancellable")
                install_cancellable = val.get_boolean ();
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


    void on_apt_finshed (string id, bool success) {
        if (!success) {
            transactions.unset (id);
            return;
        }

        if (!transactions.has_key (id)) { //transaction already removed
            return;
        }

        var action = transactions.get (id);
        if (action == "install-missing") {
            install_finished("");
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


    string[]? get_remaining_packages_for_language (string langcode) {

        string output;
        int status;

        try {
            Process.spawn_sync (null, 
                {LANGUAGE_CHECKER, "-l", langcode.substring (0, 2) , null}, 
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

    string[] get_to_remove_packages_for_language (string language) {
        var installed = get_installed_packages_for_language (language);

        string[] multilang_packs = { "chromium-browser-l10n", "poppler-data"};

        var removable = new Gee.ArrayList<string> ();
        foreach (var packet in installed) {
            if (packet in multilang_packs) {
                // nothing
            } else {
                removable.add (packet);
            }
        }

        return removable.to_array ();

    }
 
    string[]? get_installed_packages_for_language (string langcode) {

        string output;
        int status;

        try {
            Process.spawn_sync (null, 
                {LANGUAGE_CHECKER, "--show-installed", "-l", langcode.substring (0, 2) , null}, 
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
