package mini_c;

public class Log {

    public static final String log = "LOG";
    public static final String error = "ERR";
    public static final String warning = "WARN";

    public static String e(Object... objects){
        return output(error, objects);
    }

    public static String l(Object... objects){
        return output(log, objects);
    }

    public static String w(Object... objects){
        return output(warning, objects);
    }

    private static String output(String prefix, Object... objects){
        StringBuilder result = new StringBuilder();

        result.append(prefix);
        result.append((" | "));
        for (Object object : objects){
            result.append(object);
            result.append(" ");
        }
        return result.toString();
    }
}
