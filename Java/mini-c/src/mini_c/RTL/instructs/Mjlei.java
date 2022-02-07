package mini_c.RTL.instructs;

public class Mjlei extends Mubranch {
    public int n;

    Mjlei(int n) {
        this.n = n;
    }

    public String toString() {
        return "jle $" + n;
    }
}
