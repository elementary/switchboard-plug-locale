public class UbuntuInstaller : Backend {

		static const string LANGUAGE_CHECKER = "/usr/bin/check-language-support";
	static const string LOCALES_INSTALLER = "/usr/share/locales/install-language-pack";
	static const string LOCALES_REMOVER = "/usr/share/locales/install-language-pack";

	//check-language-support -l fr

	AptdProxy aptd;

public signal void install_finished (bool success, string? msg);
	public signal void remove_finished ();

	string msg;
	bool success = true;

	public UbuntuInstaller () {
		aptd = new AptdProxy ();
		aptd.connect_to_aptd ();
	}

	public override void install (string language) {
		var remaining = get_remaining_packages (language);
		var packages = remaining.strip ().split (" ");

		foreach (var packet in packages) {
			message("Packet: %s", packet);
		}

		aptd.install_packages.begin (packages, (obj, res) => {
			var test = aptd.install_packages.end (res);
			var proxy = new AptdTransactionProxy ();
			proxy.finished.connect (on_apt_finshed);
			proxy.connect_to_aptd (test);
			proxy.simulate ();
			proxy.run ();

			warning (test);

		});

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

		try {
			aptd.remove_packages.begin (remove_list, (obj, res) => {
				var test = aptd.remove_packages.end (res);
				var proxy = new AptdTransactionProxy ();
				proxy.finished.connect (on_apt_remove_finshed);
				proxy.connect_to_aptd (test);
				proxy.simulate ();
				proxy.run ();


				warning (test);

			});
		} catch (Error e) {
			warning ("Error %s", e.message);
			success = false;
			msg = e.message;
		}

		

	}

	void on_apt_remove_finshed (string id) {
		message ("REMOVE ID finished: %s", id);
		remove_finished ();
	}

	void on_apt_finshed (string id) {
		message ("INSTALL ID finished: %s", id);
		install_finished (success, msg);
	}


	string get_remaining_packages (string langcode) {

		string output;
		int status;

		Pid pid;
		Process.spawn_sync (null, 
			{LANGUAGE_CHECKER, "-l", langcode.substring (0, 2) , null}, 
			Environ.get (),
			SpawnFlags.SEARCH_PATH,
			null,
			out output,
			null,
			out status);

		return output;
	}

	string get_installed_packages (string langcode) {

		string output;
		int status;

		Pid pid;
		Process.spawn_sync (null, 
			{LANGUAGE_CHECKER, "--show-installed", "-l", langcode.substring (0, 2) , null}, 
			Environ.get (),
			SpawnFlags.SEARCH_PATH,
			null,
			out output,
			null,
			out status);

		return output;
	}
}