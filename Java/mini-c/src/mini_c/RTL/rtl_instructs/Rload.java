package mini_c.RTL.rtl_instructs;

import mini_c.RTL.Label;
import mini_c.RTL.RTL;
import mini_c.RTL.RTLVisitor;

/**
 * instruction mov i(r1), r2
 */
public class Rload extends RTL {
    public final Register r1;
    public final int i;
    public final Register r2;
    public final Label l;

    public Rload(Register r1, int i, Register r2, Label l) {
        this.r1 = r1;
        this.i = i;
        this.r2 = r2;
        this.l = l;
    }

    public void accept(RTLVisitor v) {
        v.visit(this);
    }

    public String toString() {
        return "mov " + i + "(" + r1 + ") " + r2 + " --> " + l;
    }

    public Label[] succ() {
        return new Label[]{l};
    }
}
