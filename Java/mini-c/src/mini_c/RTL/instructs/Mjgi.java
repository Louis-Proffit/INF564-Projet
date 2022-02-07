package mini_c.RTL.instructs;

public class Mjgi extends Mubranch {
    public int n;

    Mjgi(int n) {
        this.n = n;
    }

    public String toString() {
        return "jg $" + n;
    }
}
