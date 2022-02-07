package mini_c.RTL.rtl_instructs;

import mini_c.RTL.Label;
import mini_c.RTL.RTL;
import mini_c.RTL.RTLVisitor;
import mini_c.RTL.instructs.Mbinop;

/**
 * opération x86-64 binaire
 * attention au sens : c'est {@code r2 <- r2 m r1}
 */
public class Rmbinop extends RTL {
    public Mbinop m;
    public Register r1;
    public Register r2;
    public Label l;

    public Rmbinop(Mbinop m, Register r1, Register r2, Label l) {
        this.m = m;
        this.r1 = r1;
        this.r2 = r2;
        this.l = l;
    }

    public void accept(RTLVisitor v) {
        v.visit(this);
    }

    public String toString() {
        return m + " " + r1 + " " + r2 + " --> " + l;
    }

    public Label[] succ() {
        return new Label[]{l};
    }
}
