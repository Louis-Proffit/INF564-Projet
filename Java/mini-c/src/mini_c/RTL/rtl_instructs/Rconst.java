package mini_c.RTL.rtl_instructs;

import mini_c.RTL.Label;
import mini_c.RTL.RTL;
import mini_c.RTL.RTLVisitor;

/**
 * charge une constante dans un registre
 */
public class Rconst extends RTL {
    public final int i;
    public final Register r;
    public final Label l;

    public Rconst(int i, Register r, Label l) {
        this.i = i;
        this.r = r;
        this.l = l;
    }

    public void accept(RTLVisitor v) {
        v.visit(this);
    }

    public String toString() {
        return "mov $" + i + " " + r + " --> " + l;
    }

    public Label[] succ() {
        return new Label[]{l};
    }
}
