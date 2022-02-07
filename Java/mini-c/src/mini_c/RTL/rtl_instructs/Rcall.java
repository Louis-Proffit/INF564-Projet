package mini_c.RTL.rtl_instructs;

import mini_c.RTL.Label;
import mini_c.RTL.RTL;
import mini_c.RTL.RTLVisitor;

import java.util.List;

/**
 * appel de fonction
 */
public class Rcall extends RTL {
    public Register r;
    public String s;
    public List<Register> rl;
    public Label l;

    public Rcall(Register r, String s, List<Register> rl, Label l) {
        this.r = r;
        this.s = s;
        this.rl = rl;
        this.l = l;
    }

    public void accept(RTLVisitor v) {
        v.visit(this);
    }

    public String toString() {
        return r + " <- call " + s + rl + " --> " + l;
    }

    public Label[] succ() {
        return new Label[]{l};
    }
}
