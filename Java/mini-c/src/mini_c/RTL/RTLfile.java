package mini_c.RTL;

import java.util.LinkedList;
import java.util.List;


/** un programme RTL */
public class RTLfile {
    public List<RTLfun> funs;

    public RTLfile() {
        this.funs = new LinkedList<RTLfun>();  }

    void accept(RTLVisitor v) { v.visit(this); }

    /** pour débugger */
    public void print() {
        for (RTLfun fun: this.funs)
            fun.print();
    }
}
