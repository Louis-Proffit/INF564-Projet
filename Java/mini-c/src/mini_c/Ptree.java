package mini_c;

import java.util.LinkedList;

enum Binop {
	Beq, Bneq, Blt, Ble, Bgt, Bge, Badd, Bsub, Bmul, Bdiv, Band, Bor
}

enum Unop {
	Uneg, Unot, Uref, Uderef
}

// une classe pour les localisations
class Loc {
  final int line, column;
  
  Loc(int line, int column) {
    this.line = line;
    this.column = column;
  }

  @Override
  public String toString() {
    return "line " + line + ", column " + column;
  }
}

class Pstring {
  String id;
  Loc loc;
  public Pstring(String id, Loc loc) {
    this.id = id;
    this.loc = loc;
  }
  @Override
  public String toString() {
    return this.id;
  }
}

class Pfile {
	LinkedList<Pdecl> l;

	public Pfile(LinkedList<Pdecl> l) {
		super();
		this.l = l;
	}
	void accept(Pvisitor v) {
		v.visit(this);
	}
}

abstract class Pdecl {
	abstract void accept(Pvisitor v, Environement env);
}

class Pstruct extends Pdecl {
	String s;
	LinkedList<Pdeclvar> fl;

	public Pstruct(String s, LinkedList<Pdeclvar> fl) {
		super();
		this.s = s;
		this.fl = fl;
	}
	void accept(Pvisitor v, Environement env) {
		v.visit(this, env);
	}

}

class Pfun extends Pdecl {
	Ptype ty;
	String s;
	LinkedList<Pdeclvar> pl;
	Pbloc b;
	Loc loc;

	public Pfun(Ptype ty, Pstring s, LinkedList<Pdeclvar> pl, Pbloc b) {
		super();
		this.ty = ty;
		this.s = s.id;
		this.loc = s.loc;
		this.pl = pl;
		this.b = b;
	}
	void accept(Pvisitor v, Environement env) {
		v.visit(this, env);
	}

}

class Pdeclvar {
	Ptype typ;
	String id;
	Loc loc;

	public Pdeclvar(Ptype typ, Pstring id) {
		super();
		this.typ = typ;
		this.id = id.id;
		this.loc = id.loc;
	}
}

/* types */

abstract class Ptype {
	static final Ptype ptint = new PTint();

	abstract Typ accept(Pvisitor v, Environement env);
}

class PTint extends Ptype {
	Tint accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}
}

class PTypeStruct extends Ptype {
	String id;
	Loc loc;

	public PTypeStruct(Pstring id) {
		super();
		this.id = id.id;
		this.loc = id.loc;
	}
	Tstruct accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}
}

class Ppointer extends Ptype {
	Ptype type;

	public Ppointer(Ptype type) {
		super();
		this.type = type;
	}
	Tpointer accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}
}

/* expressions */

abstract class Pexpr {
  Loc loc;
  Pexpr(Loc loc) { this.loc = loc; }
  abstract Expr accept(Pvisitor v, Environement env);
}

abstract class Plvalue extends Pexpr{
  Plvalue(Loc loc) { super(loc); }
}

class Pident extends Plvalue {
	String id;

	public Pident(Pstring id) {
		super(id.loc);
		this.id = id.id;
	}
	Expr accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}

}

class Pint extends Pexpr {
	int n;

	public Pint(int n, Loc loc) {
		super(loc);
		this.n = n;
	}
	Expr accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}


}

class Parrow extends Plvalue {
	Pexpr e;
	String f;
	public Parrow(Pexpr e, String f) {
		super(e.loc);
		this.e = e;
		this.f = f;
	}
	Expr accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}

}

class Passign extends Pexpr {
  Plvalue e1;
  Pexpr e2;

  public Passign(Plvalue e1, Pexpr e2) {
    super(e1.loc);
    this.e1 = e1;
    this.e2 = e2;
  }
	Expr accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
  }
}

class Pbinop extends Pexpr {
	Binop op;
	Pexpr e1, e2;

	public Pbinop(Binop op, Pexpr e1, Pexpr e2) {
		super(e1.loc);
		this.op = op;
		this.e1 = e1;
		this.e2 = e2;
	}
	Expr accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}

}

class Punop extends Pexpr {
	Unop op;
	Pexpr e1;

	public Punop(Unop op, Pexpr e1, Loc loc) {
		super(loc);
		this.op = op;
		this.e1 = e1;
	}
	Expr accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}

}


class Pcall extends Pexpr {
	final String f;
	final LinkedList<Pexpr> l;

	Pcall(Pstring f, LinkedList<Pexpr> l) {
		super(f.loc);
		this.f = f.id;
		this.l = l;
	}
	Expr accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}

}

class Psizeof extends Pexpr {
	String id;

	public Psizeof(String id, Loc loc) {
		super(loc);
		this.id = id;
	}
	Expr accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}

}

/* instructions */

abstract class Pstmt {
  	Loc loc;
  	Pstmt(Loc loc) { this.loc = loc; }

	abstract Stmt accept(Pvisitor v, Environement env);


}

class Pbloc extends Pstmt {
	LinkedList<Pdeclvar> vl;
	LinkedList<Pstmt> sl;

	public Pbloc(LinkedList<Pdeclvar> vl, LinkedList<Pstmt> sl, Loc loc) {
		super(loc);
		this.vl = vl;
		this.sl = sl;
	}
	Stmt accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}


}

class Pskip extends Pstmt {
	Pskip(Loc loc) { super(loc); }
	Stmt accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}


}

class Preturn extends Pstmt {
	Pexpr e;

	public Preturn(Pexpr e, Loc loc) {
		super(loc);
		this.e = e;
	}

	Stmt accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}


}

class Pif extends Pstmt {
	Pexpr e;
	Pstmt s1, s2;

	public Pif(Pexpr e, Pstmt s1, Pstmt s2, Loc loc) {
		super(loc);
		this.e = e;
		this.s1 = s1;
		this.s2 = s2;
	}
	Stmt accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}

}

class Peval extends Pstmt {
	Pexpr e;

	public Peval(Pexpr e) {
		super(e.loc);
		this.e = e;
	}
	Stmt accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}

}

class Pwhile extends Pstmt {
	Pexpr e;
	Pstmt s1;

	public Pwhile(Pexpr e, Pstmt s1, Loc loc) {
		super(loc);
		this.e = e;
		this.s1 = s1;
	}
	Stmt accept(Pvisitor v, Environement env) {
		return v.visit(this, env);
	}

}

interface Pvisitor {

	public Tint visit(PTint n, Environement env);
	
	public Tstruct visit(PTypeStruct n, Environement env);

	public Tpointer visit(Ppointer n, Environement env);
	
	public Expr visit(Pint n, Environement env);

	public Expr visit(Pident n, Environement env);

	public Expr visit(Punop n, Environement env);
  
	public Expr visit(Passign n, Environement env);

	public Expr visit(Pbinop n, Environement env);

	public Expr visit(Parrow n, Environement env);

	public Expr visit(Pcall n, Environement env);

	public Expr visit(Psizeof n, Environement env);

	public Stmt visit(Pskip n, Environement env);

	public Stmt visit(Peval n, Environement env);

	public Stmt visit(Pif n, Environement env);

	public Stmt visit(Pwhile n, Environement env);

	public Stmt visit(Pbloc n, Environement env);

	public Stmt visit(Preturn n, Environement env);

	public void visit(Pfun n, Environement env);

	public void visit(Pstruct n, Environement env);

	public File visit(Pfile n);
}
