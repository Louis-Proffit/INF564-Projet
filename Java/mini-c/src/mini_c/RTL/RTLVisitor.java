package mini_c.RTL;

import mini_c.RTL.rtl_instructs.*;

/**
 * visiteur pour parcourir la forme RTL
 * (pour la suite du compilateur)
 */

public interface RTLVisitor {
    public void visit(Rconst o);

    public void visit(Rload o);

    public void visit(Rstore o);

    public void visit(Rmunop o);

    public void visit(Rmbinop o);

    public void visit(Rmubranch o);

    public void visit(Rmbbranch o);

    public void visit(Rcall o);

    public void visit(Rgoto o);

    public void visit(RTLfun o);

    public void visit(RTLfile o);
}
