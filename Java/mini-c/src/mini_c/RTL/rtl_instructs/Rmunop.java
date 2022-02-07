package mini_c.RTL.rtl_instructs;

import mini_c.RTL.Label;
import mini_c.RTL.RTL;
import mini_c.RTL.RTLVisitor;
import mini_c.RTL.instructs.Munop;

/**
 * opération x86-64 unaire
 */
public class Rmunop extends RTL {
    public Munop m;
    public Register r;
    public Label l;

    public Rmunop(Munop m, Register r, Label l) {
        this.m = m;
        this.r = r;
        this.l = l;
    }

    public void accept(RTLVisitor v) {
        v.visit(this);
    }

    public String toString() {
        return m + " " + r + " --> " + l;
    }

    public Label[] succ() {
        return new Label[]{l};
    }
}
