package mini_c.RTL.rtl_instructs;

import mini_c.RTL.Label;
import mini_c.RTL.RTL;
import mini_c.RTL.RTLVisitor;

/**
 * instruction mov r1, i(r2)
 */
public class Rstore extends RTL {
    public final Register r1;
    public final Register r2;
    public final int i;
    public final Label l;

    public Rstore(Register r1, Register r2, int i, Label l) {
        this.r1 = r1;
        this.r2 = r2;
        this.i = i;
        this.l = l;
    }

    public void accept(RTLVisitor v) {
        v.visit(this);
    }

    public String toString() {
        return "mov " + r1 + " " + i + "(" + r2 + ") " + " --> " + l;
    }

    public Label[] succ() {
        return new Label[]{l};
    }
}
