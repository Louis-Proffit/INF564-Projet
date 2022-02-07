package mini_c.RTL.rtl_instructs;

import mini_c.RTL.Label;
import mini_c.RTL.RTL;
import mini_c.RTL.RTLVisitor;
import mini_c.RTL.instructs.Mbbranch;

/**
 * instruction x86-64 de branchement (binaire)
 * attention au sens : c'est le résultat de {@code r2 cmp r1}
 */
public class Rmbbranch extends RTL {
    public Mbbranch m;
    public Register r1;
    public Register r2;
    public Label l1;
    public Label l2;

    Rmbbranch(Mbbranch m, Register r1, Register r2, Label l1, Label l2) {
        this.m = m;
        this.r1 = r1;
        this.r2 = r2;
        this.l1 = l1;
        this.l2 = l2;
    }

    public void accept(RTLVisitor v) {
        v.visit(this);
    }

    public String toString() {
        return m + " " + r1 + " " + r2 + " --> " + l1 + ", " + l2;
    }

    public Label[] succ() {
        return new Label[]{l1, l2};
    }
}
