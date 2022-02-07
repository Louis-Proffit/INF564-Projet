package mini_c;

import mini_c.RTL.*;
import mini_c.RTL.rtl_instructs.Register;

import java.util.HashMap;
import java.util.LinkedList;

abstract class Typ {

	abstract boolean typeof(Typ otherType);
}

class Tint extends Typ {

	static final Tint INSTANCE = new Tint();
	private Tint() {}

	@Override
	boolean typeof(Typ otherType) {
		return otherType == Tint.INSTANCE || otherType == Ttypenull.INSTANCE;
	}

	@Override
	public String toString() {
	  return "int";
	}
}

class Tstruct extends Typ {

	public Structure s;

	Tstruct(Structure s) {
		this.s = s;
	}

	@Override
	boolean typeof(Typ otherType) {
		if (otherType instanceof Tstruct && ((Tstruct) otherType).s.str_name.equals(s.str_name))
			return true;
		return otherType == Ttypenull.INSTANCE || otherType == Tvoidstar.INSTANCE;
	}

	@Override
	public String toString() {
	  return "struct " + s.str_name;
	}
}

class Tpointer extends Typ {

	public Typ typ;

	Tpointer(Typ typ) {
		this.typ = typ;
	}

	@Override
	boolean typeof(Typ otherType) {
		return (otherType instanceof Tpointer && ((Tpointer) otherType).typ.typeof(typ));
	}

	@Override
	public String toString() {
		return typ.toString()+"*";
	}
}

class Tvoidstar extends Typ {

	static final Tvoidstar INSTANCE = new Tvoidstar();

	private Tvoidstar() {
	}

	@Override
	boolean typeof(Typ otherType) {
		return otherType == INSTANCE || otherType instanceof Tstruct;
	}
	@Override
	public String toString() {
	  return "void*";
	}
}

class Ttypenull extends Typ {

	static final Ttypenull INSTANCE = new Ttypenull();
	private Ttypenull() {
	}

	@Override
	public String toString() {
	  return "typenull";
	}

	@Override
	boolean typeof(Typ otherType) {
		return otherType == INSTANCE || otherType == Tint.INSTANCE || otherType instanceof Tstruct;
	}
}

class Structure {
	public String str_name;
	public HashMap<String, Field> fields;
	// on pourra ajouter plus tard ici la taille totale de la structure

	Structure(String str_name) {
		this.str_name = str_name;
		this.fields = new HashMap<>();
	}
}

class Field {
	public String field_name;
	public Typ field_typ;
	// on pourra ajouter plus tard ici la position du champ dans la structure

	Field(String field_name, Typ field_typ) {
		this.field_name = field_name;
		this.field_typ = field_typ;
	}
}

class Decl_var {
	public Typ t;
	public String name;

	Decl_var(Typ t, String i) {
		this.t = t;
		this.name = i;
	}
	
	@Override
	public String toString() {
	  return t.toString() + " " + name;
	}
}

// expression

abstract class Expr {
	public Typ typ; // chaque expression est décorée par son type

	public Expr(Typ typ) {
		this.typ = typ;
	}

	abstract Label accept(Visitor v, Label nextLabel, Register register);
}

class Econst extends Expr {
	public int i;

	Econst(Typ typ, int i) {
		super(typ);
		this.i = i;
	}

	Label accept(Visitor v, Label nextLabel, Register register) {
		return v.visit(this, nextLabel, register);
	}
}

class Eaccess_local extends Expr {
	public String i;

	Eaccess_local(Typ typ, String i) {
		super(typ);
		this.i = i;
	}

	Label accept(Visitor v, Label nextLabel, Register register) {
		return v.visit(this, nextLabel, register);
	}
}

class Eaccess_field extends Expr {
	public Expr e;
	public Field f;

	Eaccess_field(Typ typ, Expr e, Field f) {
		super(typ);
		this.e = e;
		this.f = f;
	}

	Label accept(Visitor v, Label nextLabel, Register register) {
		return v.visit(this, nextLabel, register);
	}
}

class Eassign_local extends Expr {
	public String i;
	public Expr e;

	Eassign_local(Typ typ, String i, Expr e) {
		super(typ);
		this.i = i;
		this.e = e;
	}

	Label accept(Visitor v, Label nextLabel, Register register) {
		return v.visit(this, nextLabel, register);
	}
}

class Eassign_field extends Expr {
	public Expr e1;
	public Field f;
	public Expr e2;

	Eassign_field(Typ typ, Expr e1, Field f, Expr e2) {
		super(typ);
		this.e1 = e1;
		this.f = f;
		this.e2 = e2;
	}

	Label accept(Visitor v, Label nextLabel, Register register) {
		return v.visit(this, nextLabel, register);
	}
}

class Eunop extends Expr {
	public Unop u;
	public Expr e;

	Eunop(Typ typ, Unop u, Expr e) {
		super(typ);
		this.u = u;
		this.e = e;
	}

	Label accept(Visitor v, Label nextLabel, Register register) {
		return v.visit(this, nextLabel, register);
	}
}

class Ebinop extends Expr {
	public Binop b;
	public Expr e1;
	public Expr e2;

	Ebinop(Typ typ, Binop b, Expr e1, Expr e2) {
		super(typ);
		this.b = b;
		this.e1 = e1;
		this.e2 = e2;
	}

	Label accept(Visitor v, Label nextLabel, Register register) {
		return v.visit(this, nextLabel, register);
	}
}

class Ecall extends Expr {
	public String i;
	public LinkedList<Expr> el;

	Ecall(Typ typ, String i, LinkedList<Expr> el) {
		super(typ);
		this.i = i;
		this.el = el;
	}

	Label accept(Visitor v, Label nextLabel, Register register) {
		return v.visit(this, nextLabel, register);
	}
}

class Esizeof extends Expr {
	public Structure s;

	Esizeof(Typ typ, Structure s) {
		super(typ);
		this.s = s;
	}

	Label accept(Visitor v, Label nextLabel, Register register) {
		return v.visit(this, nextLabel, register);
	}
}

// instruction

abstract class Stmt {
	abstract Label accept(Visitor v, Label nextLabel);
}

class Sskip extends Stmt {
	Sskip() {
	}

	Label accept(Visitor v, Label nextLabel) {
		return v.visit(this, nextLabel);
	}
}

class Sexpr extends Stmt {
	public Expr e;

	Sexpr(Expr e) {
		this.e = e;
	}

	Label accept(Visitor v, Label nextLabel) {
		return v.visit(this, nextLabel);
	}
}

class Sif extends Stmt {
	public Expr e;
	public Stmt s1;
	public Stmt s2;

	Sif(Expr e, Stmt s1, Stmt s2) {
		this.e = e;
		this.s1 = s1;
		this.s2 = s2;
	}

	Label accept(Visitor v, Label nextLabel) {
		return v.visit(this, nextLabel);
	}
}

class Swhile extends Stmt {
	public Expr e;
	public Stmt s;

	Swhile(Expr e, Stmt s) {
		this.e = e;
		this.s = s;
	}

	@Override
	Label accept(Visitor v, Label nextLabel) {
		return v.visit(this, nextLabel);
	}
}

class Sblock extends Stmt {
	public LinkedList<Decl_var> dl;
	public LinkedList<Stmt> sl;

	Sblock(LinkedList<Decl_var> dl, LinkedList<Stmt> sl) {
		this.dl = dl;
		this.sl = sl;
	}

	Label accept(Visitor v, Label nextLabel) {
		return v.visit(this, nextLabel);
	}
}

class Sreturn extends Stmt {
	public Expr e;

	Sreturn(Expr e) {
		this.e = e;
	}

	Label accept(Visitor v, Label nextLabel) {
		return v.visit(this, nextLabel);
	}
}

// fonction

class Decl_fun {
	public Typ fun_typ;
	public String fun_name;
	public LinkedList<Decl_var> fun_formals;
	public Stmt fun_body;

	Decl_fun(Typ fun_typ, String fun_name, LinkedList<Decl_var> fun_formals,
			Stmt fun_body) {
		this.fun_typ = fun_typ;
		this.fun_name = fun_name;
		this.fun_formals = fun_formals;
		this.fun_body = fun_body;
	}

	RTLfun accept(Visitor v) {
		return v.visit(this);
	}
}

// programme = liste de fonctions

class File {
	public LinkedList<Decl_fun> funs;

	File(LinkedList<Decl_fun> funs) {
		this.funs = funs;
	}

	RTLfile accept(Visitor v) {
		return v.visit(this);
    }
}

interface Visitor {

	Label visit(Econst n, Label nextLabel, Register register);

	Label visit(Eaccess_local n, Label nextLabel, Register register);

	Label visit(Eaccess_field n, Label nextLabel, Register register);

	Label visit(Eassign_local n, Label nextLabel, Register register);

	Label visit(Eassign_field n, Label nextLabel, Register register);

	Label visit(Eunop n, Label nextLabel, Register register);

	Label visit(Ebinop n, Label nextLabel, Register register);

	Label visit(Ecall n, Label nextLabel, Register register);

	Label visit(Esizeof n, Label nextLabel, Register register);

	Label visit(Sskip n, Label nextLabel);

	Label visit(Sexpr n, Label nextLabel);

	Label visit(Sif n, Label nextLabel);

	Label visit(Swhile n, Label nextLabel);

	Label visit(Sblock n, Label nextLabel);

	Label visit(Sreturn n, Label nextLabel);

	RTLfun visit(Decl_fun n);

	RTLfile visit(File n);
}
