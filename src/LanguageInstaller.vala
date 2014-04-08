public class LanguageInstaller : Object {


	public LanguageInstaller () {
	
	}

	public void install (string language) {
		message("installing language: %s", language);
	}

	static LanguageInstaller? instance = null;

	public static LanguageInstaller get_default () {
		if (instance == null) {
			instance = new LanguageInstaller ();
		}
		return instance;
	}
}