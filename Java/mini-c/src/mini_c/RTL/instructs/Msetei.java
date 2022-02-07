package mini_c.RTL.instructs;

public class Msetei extends Munop {
    public int n;

    Msetei(int n) {
        this.n = n;
    }

    public String toString() {
        return "sete $" + n;
    }
}
