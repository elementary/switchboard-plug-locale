public class Utils : Object{

    public Utils () {

    }
    
    public static string[]? get_installed_languages () {

        string output;
        int status;

        try {
            Process.spawn_sync (null, 
                {"/usr/share/language-tools/language-options" , null}, 
                Environ.get (),
                SpawnFlags.SEARCH_PATH,
                null,
                out output,
                null,
                out status);

            return output.split("\n");

        } catch (Error e) {
            return null;
        }

        
    }

    public static string[]? get_installed_locales () {

        string output;
        int status;

        try {
            Process.spawn_sync (null, 
                {"/usr/share/language-tools/language-options" , null}, 
                Environ.get (),
                SpawnFlags.SEARCH_PATH,
                null,
                out output,
                null,
                out status);

            return output.split("\n");
        
        } catch (Error e) {
            return null;
        }

    }

    static Utils? instance = null;

    public static Utils get_default () {
        if (instance == null) {
            instance = new Utils ();
        }
        return instance;
    }
}