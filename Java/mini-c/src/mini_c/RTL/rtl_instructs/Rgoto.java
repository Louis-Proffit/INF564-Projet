package mini_c.RTL.rtl_instructs;

import mini_c.RTL.Label;
import mini_c.RTL.RTL;
import mini_c.RTL.RTLVisitor;

/**
 * saut inconditionnel
 */
public class Rgoto extends RTL {
    public Label l;

    Rgoto(Label l) {
        this.l = l;
    }

    public void accept(RTLVisitor v) {
        v.visit(this);
    }

    public String toString() {
        return "goto " + l;
    }

    public Label[] succ() {
        return new Label[]{l};
    }
}
