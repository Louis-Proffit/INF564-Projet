package mini_c.RTL.instructs;

public class Maddi extends Munop {
    public int n;

    Maddi(int n) {
        this.n = n;
    }

    public String toString() {
        return "add $" + n;
    }
}
