package mini_c;

import mini_c.RTL.*;
import mini_c.RTL.instructs.Mbinop;
import mini_c.RTL.instructs.Mjz;
import mini_c.RTL.instructs.Munop;
import mini_c.RTL.rtl_instructs.*;

import java.util.*;
import java.util.function.Consumer;

public class ToRTL implements Visitor {

    private HashMap<String, Register> locals;
    private RTLfun fun;

    public RTLfile translate(File file){
        return file.accept(this);
    }

    @Override
    public Label visit(Econst n, Label nextLabel, Register register) {
        return fun.body.add(new Rconst(n.i, register, nextLabel));
    }

    @Override
    public Label visit(Eaccess_local n, Label nextLabel, Register register) {
        return fun.body.add(new Rmbinop(Mbinop.Mmov, locals.get(n.i), register, nextLabel));
    }

    @Override
    public Label visit(Eaccess_field n, Label nextLabel, Register register) {
        return null;
    }

    @Override
    public Label visit(Eassign_local n, Label nextLabel, Register register) {
        Label assignLabel = fun.body.add(new Rmbinop(Mbinop.Mmov, register, locals.get(n.i), nextLabel));
        return n.e.accept(this, assignLabel, register);
    }

    @Override
    public Label visit(Eassign_field n, Label nextLabel, Register register) {
        return null;
    }

    @Override
    public Label visit(Eunop n, Label nextLabel, Register register) {
        switch (n.u){
            case Uneg:
                Register exprRegister = new Register();
                Label l1 = fun.body.add(new Rmbinop(Mbinop.Msub, exprRegister, register, nextLabel));
                Label l2 = fun.body.add(new Rconst(0, register, l1));
                return n.e.accept(this, l2, exprRegister);
            case Unot:
                break;
            case Uref:
                break;
            case Uderef:
                break;
        }
        throw new RTLException("Not implemented");
    }

    @Override
    public Label visit(Ebinop n, Label nextLabel, Register register) {
        Register r1 = new Register();
        Register r2 = new Register();
        Mbinop binop;
        switch (n.b){
            case Badd:
                binop = Mbinop.Madd;
                break;
            case Bsub:
                binop = Mbinop.Msub;
                break;
            case Bmul:
                binop = Mbinop.Mmul;
                break;
            case Bdiv:
                binop = Mbinop.Mdiv;
                break;
            default:
                throw new RTLException("Not implemented");
        }
        Label l1 = fun.body.add(new Rmbinop(binop, r1, r2, nextLabel));
        Label l2 = n.e2.accept(this, l1, r2);
        return n.e1.accept(this, l2, r1);
    }

    @Override
    public Label visit(Ecall n, Label nextLabel, Register register) {
        Log.l("Calling function",fun.name,"with",n.el.size(),"arguments");
        Rcall call = new Rcall(register, n.i, fun.formals,nextLabel);
        Label previousLabel = fun.body.add(call);
        LinkedList<Register> registers = new LinkedList<>();
        for (int i = n.el.size() - 1 ; i >= 0 ; i--){
            Register reg = new Register();
            previousLabel = n.el.get(i).accept(this, previousLabel, reg);
            registers.add(reg);
        }
        call.rl = registers;
        return previousLabel;
    }

    @Override
    public Label visit(Esizeof n, Label nextLabel, Register register) {
        return fun.body.add(new Rconst(64 * n.s.fields.size(),register, nextLabel));
    }

    @Override
    public Label visit(Sskip n, Label nextLabel) {
        return nextLabel;
    }

    @Override
    public Label visit(Sexpr n, Label nextLabel) {
        return n.e.accept(this, nextLabel, new Register()); // TODO : random register ?
    }

    @Override
    public Label visit(Sif n, Label nextLabel) {
        Label lTrue = n.s1.accept(this, nextLabel);
        Label lFalse = n.s1.accept(this, nextLabel);
        Register conditionRegister = new Register();
        Label jumpLabel = fun.body.add(new Rmubranch(new Mjz(), conditionRegister, lTrue, lFalse));
        return n.e.accept(this, jumpLabel, conditionRegister);
    }

    @Override
    public Label visit(Swhile n, Label nextLabel) {
        return null;
    }

    @Override
    public Label visit(Sblock n, Label nextLabel) {
        Label previousLabel = nextLabel;
        for (int i = n.dl.size() - 1 ; i >= 0 ; i--){
            Register register = new Register();
            fun.locals.add(register);
            locals.put(n.dl.get(i).name, register);
        }
        for (int i = n.sl.size() - 1 ; i >= 0 ; i--){
            previousLabel = n.sl.get(i).accept(this, previousLabel);
        }
        return previousLabel;
    }

    @Override
    public Label visit(Sreturn n, Label nextLabel) {
        return n.e.accept(this, fun.exit, fun.result);
    }

    @Override
    public RTLfun visit(Decl_fun n) {
        System.out.println(Log.l("RTLing declaration of function",n.fun_name,"with",n.fun_formals.size(),"args"));

        fun = new RTLfun(n.fun_name);
        locals = new HashMap<>();

        fun.body = new RTLgraph();
        fun.exit = new Label();
        fun.result = new Register();
        for (Decl_var arg : n.fun_formals){
            Register register = new Register();
            locals.put(arg.name, register); // Adding the arguments as local variables for the function
            fun.formals.add(register);
        }

        fun.entry = n.fun_body.accept(this, fun.exit);

        return fun;
    }

    @Override
    public RTLfile visit(File n) {
        RTLfile file = new RTLfile();
        n.funs.forEach(
                decl_fun -> file.funs.add(decl_fun.accept(ToRTL.this))
        );

        return file;
    }
}
