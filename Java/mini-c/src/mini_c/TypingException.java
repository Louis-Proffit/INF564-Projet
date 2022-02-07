package mini_c;

public class TypingException extends RuntimeException{

    public TypingException(Loc loc, Object... objects){
        super(Log.e(loc.line,":",loc.line, "Typing failed", "|", objects));
    }
}
