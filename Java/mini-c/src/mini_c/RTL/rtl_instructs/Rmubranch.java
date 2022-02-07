package mini_c.RTL.rtl_instructs;

import mini_c.RTL.Label;
import mini_c.RTL.RTL;
import mini_c.RTL.RTLVisitor;
import mini_c.RTL.instructs.Mubranch;

/**
 * instruction x86-64 de branchement (unaire)
 */
public class Rmubranch extends RTL {
    public Mubranch m;
    public Register r;
    public Label l1;
    public Label l2;

    public Rmubranch(Mubranch m, Register r, Label l1, Label l2) {
        this.m = m;
        this.r = r;
        this.l1 = l1;
        this.l2 = l2;
    }

    public void accept(RTLVisitor v) {
        v.visit(this);
    }

    public String toString() {
        return m + " " + r + " --> " + l1 + ", " + l2;
    }

    public Label[] succ() {
        return new Label[]{l1, l2};
    }
}
