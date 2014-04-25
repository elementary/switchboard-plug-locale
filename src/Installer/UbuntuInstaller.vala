public class UbuntuInstaller : Backend {

	static const string LANGUAGE_CHECKER = "/usr/bin/check-language-support";
	static const string LOCALES_INSTALLER = "/usr/share/locales/install-language-pack";
	static const string LOCALES_REMOVER = "/usr/share/locales/install-language-pack";

	//check-language-support -l fr

	AptdProxy aptd;

	public signal void install_finished (string langcode);
	public signal void remove_finished (string langcode);

	string msg;
	bool success = true;

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
		var remaining = get_remaining_packages (language);
		var packages = remaining.strip ().split (" ");

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
		proxy.finished.connect (on_apt_finshed);

		try {
			proxy.connect_to_aptd (transaction_id);
			proxy.simulate ();

			proxy.run ();
		} catch (Error e) {
			warning ("Could no run transaction");
			success = false;
			msg = e.message;
		}

	}

	public override void remove (string languagecode) {

		var inst = get_installed_packages (languagecode);
		//message (inst);
		var installed = inst.strip().split(" ");
		var miss = get_remaining_packages (languagecode);
		//message (miss);
		var missing = miss.strip().split(" ");


		var total_remove = new Gee.ArrayList<string>(null);//[installed.length];
		var i = 0;
		foreach (var inst_lang in installed) {
			bool not_installed = false;
			foreach (var miss_lang in missing) {
				if (miss_lang == inst_lang) {
					not_installed = true;
				}
			}

			if (!not_installed) {
				total_remove.add (inst_lang);
				message("Packages remove: %s", inst_lang);
			} else {
				message("Packages not remove: %s", inst_lang);
			}
		}


		var remove_list = new string[total_remove.size];
		i = 0;
		total_remove.@foreach ((val) => {
			remove_list[i++] = val;
			return true;
		});

		aptd.remove_packages.begin (remove_list, (obj, res) => {

			try {
				var transaction_id = aptd.remove_packages.end (res);
				transactions.@set (transaction_id, "r-"+languagecode);
				run_transaction (transaction_id);
			} catch (Error e) {
				warning ("Could not queue deletions");
			}

		});


		

	}


	void on_apt_finshed (string id) {

		var action = transactions.get (id);
		var lang = action[2:action.length];

		if (action[0:1] == "i") { // install

			install_finished (lang);

		} else {

			remove_finished (lang);
		}

	}


	string? get_remaining_packages (string langcode) {

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
		
		return output;

	}

	string? get_installed_packages (string langcode) {

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

		return output;

	}
}