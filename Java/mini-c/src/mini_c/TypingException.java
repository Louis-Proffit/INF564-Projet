package mini_c;

public class TypingException extends RuntimeException{

    private static String build(Loc loc, Object... objects){
        StringBuilder result = new StringBuilder();

        result.append(loc.line + 1);
        result.append(":");
        result.append(loc.column + 1);
        result.append(" | ");
        result.append("Typing failed | ");

        for (Object object : objects){
            result.append(object);
            result.append(" ");
        }

        return result.toString();
    }

    public TypingException(Loc loc, Object... objects){
        super(build(loc, objects));
    }
}
