package mini_c.RTL.instructs;

public class Msetnei extends Munop {
    public int n;

    Msetnei(int n) {
        this.n = n;
    }

    public String toString() {
        return "setne $" + n;
    }
}
