public class UbuntuInstaller : Backend {

    static const string LANGUAGE_CHECKER = "/usr/bin/check-language-support";
    static const string LOCALES_INSTALLER = "/usr/share/locales/install-language-pack";
    static const string LOCALES_REMOVER = "/usr/share/locales/install-language-pack";

    //check-language-support -l fr

    AptdProxy aptd;

    public signal void install_finished (string langcode);
    public signal void remove_finished (string langcode);

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

    public override void install (string language) {
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
                warning ("Could not queue downloads");
            }
            

        });

    }

    void run_transaction (string transaction_id) {

        var proxy = new AptdTransactionProxy ();
        proxy.finished.connect (() => {
            on_apt_finshed (transaction_id, true);
        });

        try {
            proxy.connect_to_aptd (transaction_id);
            proxy.simulate ();

            proxy.run ();
        } catch (Error e) {
            on_apt_finshed (transaction_id, false);
            warning ("Could no run transaction");
        }

    }

    public override void remove (string languagecode) {

        var installed = get_installed_packages_for_language (languagecode);

        aptd.remove_packages.begin (installed, (obj, res) => {

            try {
                var transaction_id = aptd.remove_packages.end (res);
                transactions.@set (transaction_id, "r-"+languagecode);
                run_transaction (transaction_id);
            } catch (Error e) {
                warning ("Could not queue deletions");
            }

        });


        

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
        var lang = action[2:action.length];

        message ("ID %s -> %s", id, success ? "success" : "failed");

        if (action[0:1] == "i") { // install

            install_finished (lang);

        } else {

            remove_finished (lang);
        }

        //transactions.unset (id);
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