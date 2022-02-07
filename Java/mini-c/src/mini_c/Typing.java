package mini_c;

import java.util.*;

public class Typing implements Pvisitor {
	
	// il faut compléter le visiteur ci-dessous pour réaliser le typage
	File file;

	public static void addDefaultFunctions(){
		LinkedList<Decl_var> vars_putchar = new LinkedList<>();
		vars_putchar.add(new Decl_var(Tint.INSTANCE, "c"));
		Environement.functions.put(
				"putchar",
				new Decl_fun(
						Tint.INSTANCE,
						"putchar",
						vars_putchar,
						new Sskip()
						)
		);
		LinkedList<Decl_var> vars_sbrk = new LinkedList<>();
		vars_sbrk.add(new Decl_var(Tint.INSTANCE, "n"));
		Environement.functions.put(
				"sbrk",
				new Decl_fun(
						Tvoidstar.INSTANCE,
						"sbrk",
						vars_sbrk,
						new Sskip()
				)
		);
	}

	@Override
	public File visit(Pfile n) {
		file = new File(new LinkedList<>());
		Environement environement = new Environement(null);
		addDefaultFunctions();
		for (Pdecl decl : n.l){
			decl.accept(this, environement);
		}
		Decl_fun main = Environement.functions.get("main");
		if (main == null){
			throw new RuntimeException("Main function missing");
		} else if (!main.fun_typ.typeof(Tint.INSTANCE)){
			throw new RuntimeException("Type of function main has to be int, not " + main.fun_typ);
		} else if (main.fun_formals.size() > 0){
			throw new RuntimeException("Main function should not take any arguments");
		} else {
			return file;
		}
	}

	@Override
	public Tint visit(PTint n, Environement env) {
		return Tint.INSTANCE;
	}

	@Override
	public Tpointer visit(Ppointer n, Environement env) {
		return new Tpointer(n.accept(this, env).typ);
	}

	@Override
	public Tstruct visit(PTypeStruct n, Environement env) {
		return Environement.structs.get(n.id);
	}

	@Override
	public Expr visit(Pint n, Environement env) {
		if (n.n == 0){
			return new Econst(Ttypenull.INSTANCE, n.n);
		} else {
			return new Econst(Tint.INSTANCE, n.n);
		}
	}

	@Override
	public Expr visit(Pident n, Environement env) {
		if (!env.locals.containsKey(n.id)){
			throw new TypingException(n.loc, "Ident", n.id, "not declared");
		}
		return new Eaccess_local(env.locals.get(n.id), n.id);
	}

	@Override
	public Expr visit(Punop n, Environement env) {
		Expr e = n.e1.accept(this, env);
		switch(n.op){
			case Uneg :{
				if (e.typ instanceof Tint){
					return new Eunop(Tint.INSTANCE, Unop.Uneg, e);
				} else {
					throw new RuntimeException("Negation only applies to int expr");
				}
			}
			case Unot : {
				return new Eunop(Tint.INSTANCE, Unop.Unot,e);
			}
			case Uref:
				if (e.typ instanceof Tpointer){
					return new Eunop(((Tpointer)e.typ).typ, Unop.Uref, e);
				} else {
					throw new TypingException(n.loc, "Can't use & on a non pointer type (", e.typ,")");
				}
			case Uderef:
				return new Eunop(new Tpointer(e.typ), Unop.Uderef, e);
		}
		return null;
	}

	@Override
	public Expr visit(Passign n, Environement env) {
		Expr e2 = n.e2.accept(this, env);
		if (n.e1 instanceof Parrow){
			Parrow parrow = (Parrow) n.e1;
			Expr e1 = parrow.e.accept(this, env);
			if (e1.typ instanceof Tstruct){
				Tstruct tstructp = (Tstruct)e1.typ;
				Field fieldTyp = tstructp.s.fields.get(parrow.f);
				if (fieldTyp.field_typ.typeof(e2.typ)){
					return new Eassign_field(fieldTyp.field_typ, e1, fieldTyp, e2);
				} else {
					throw new TypingException(n.loc,"Can't assign expression of type", e2.typ, "to field of type", fieldTyp.field_typ);
				}
			} else {
				throw new TypingException(n.loc,"Can't assign to a field of a non struct ident (", e1.typ, "instead)");
			}
		} else if (n.e1 instanceof Pident){
			Expr e1 = n.e1.accept(this, env);
			if (e1.typ.typeof(e2.typ)){
				return new Eassign_local(e1.typ, ((Pident)n.e1).id, e2);
			} else {
				throw new TypingException(n.loc,"Can't assign expression of type", e2.typ, "to variable of type", e1.typ);
			}
		} else {
			throw new RuntimeException("Unreachable");
		}
	}

	@Override
	public Expr visit(Pbinop n, Environement env) {
		Expr e1 = n.e1.accept(this, env);
		Expr e2 = n.e2.accept(this, env);
		switch (n.op){
			case Beq:
			case Bneq:
			case Bge:
			case Bgt:
			case Ble:
			case Blt:
				if (e1.typ.typeof(e2.typ)){
					return new Ebinop(Tint.INSTANCE, n.op, e1, e2);
				} else {
					throw new TypingException(n.loc, "Illegal operation",n,"between types",e1.typ,"and",e2.typ);
				}
			case Badd:
			case Bdiv:
			case Bmul:
			case Bsub:
				if (e1.typ.typeof(Tint.INSTANCE) && e2.typ.typeof(Tint.INSTANCE)){
					return new Ebinop(Tint.INSTANCE, n.op, e1, e2);
				} else {
					throw new RuntimeException("Operation between " + e1.typ + " and " + e2.typ + " not allowed");
				}
			case Band:
			case Bor:
			default:
				return new Ebinop(Tint.INSTANCE, n.op, e1, e2);
		}
	}

	@Override
	public Expr visit(Parrow n, Environement env) {
		Expr e = n.e.accept(this, env);
		if (e.typ instanceof Tstruct){
			Tstruct tstructp = (Tstruct)e.typ;
			Typ resultTyp = tstructp.s.fields.get(n.f).field_typ;
			if (resultTyp != null){
				return new Eaccess_field(resultTyp, e, new Field(n.f, resultTyp));
			} else {
				throw new RuntimeException("No field matching the name of the right side of arrow");
			}
		} else {
			throw new RuntimeException("Can't use -> for a non struct type expression");
		}
	}

	@Override
	public Expr visit(Pcall n, Environement env) {
		Decl_fun fun = Environement.functions.get(n.f);
		Iterator<Pexpr> varIterator = n.l.iterator();
		Iterator<Decl_var> argIterator = fun.fun_formals.iterator();
		LinkedList<Expr> exprs = new LinkedList<>();
		while(varIterator.hasNext() && argIterator.hasNext()){
			Expr e = varIterator.next().accept(this, env);
			Decl_var var = argIterator.next();
			if (!e.typ.typeof(var.t)){
				throw new TypingException(n.loc,"Calling function", n.f, "with argument", var.name, "of type", e.typ, "instead of", var.t);
			} else {
				exprs.add(e);
			}
		}
		if (varIterator.hasNext() || argIterator.hasNext()){
			throw new TypingException(n.loc,"Calling function", n.f, "with a wrong number of arguments");
		}
		return new Ecall(fun.fun_typ, n.f, exprs);
	}

	@Override
	public Expr visit(Psizeof n, Environement env) {
		Tstruct typ = Environement.structs.get(n.id);
		if (typ == null){
			throw new RuntimeException("Struct inside of sizeof not defined");
		} else {
			return new Esizeof(Tint.INSTANCE, typ.s);
		}
	}

	@Override
	public Stmt visit(Pskip n, Environement env) {
		return new Sskip();
	}

	@Override
	public Stmt visit(Peval n, Environement env) {
		return new Sexpr(n.e.accept(this, env));
	}

	@Override
	public Stmt visit(Pif n, Environement env) {
		return new Sif(
				n.e.accept(this, env),
				n.s1.accept(this, env),
				n.s2.accept(this, env)
		);
	}

	@Override
	public Stmt visit(Pwhile n, Environement env) {
		return new Swhile(
				n.e.accept(this, env),
				n.s1.accept(this, env)
		);
	}

	@Override
	public Stmt visit(Pbloc n, Environement env) {
		Environement environement = env.copy(env.returnType); // block shares same return type
		LinkedList<Decl_var> vars = new LinkedList<>();
		for (Pdeclvar pdeclvar : n.vl){ // Put all variables
			Typ typ = pdeclvar.typ.accept(this, env);
			Decl_var decl_var = new Decl_var(typ, pdeclvar.id);
			if (environement.locals.containsKey(pdeclvar.id)){
				if (!env.locals.containsKey(pdeclvar.id)){
					// If the variable is already declared but is not declared in the parent body, it means it is being redifined
					// Else you can overwrite a varible of the parent body
					throw new TypingException(pdeclvar.loc, "Variable", pdeclvar.id, "already declared");
				}
			} else {
				environement.locals.put(pdeclvar.id, typ);
				vars.add(decl_var);
			}
		}
		LinkedList<Stmt> stmts = new LinkedList<>();
		for (Pstmt stmt : n.sl){
			stmts.add(stmt.accept(this, environement)); // Evaluate all statements and add those to the list
		}
		return new Sblock(vars, stmts);

	}

	@Override
	public Stmt visit(Preturn n, Environement env) {
		Expr e = n.e.accept(this, env);
		if (!e.typ.typeof(env.returnType)){
			throw new RuntimeException("Wrong return type : " + e.typ + " instead of " + env.returnType + " for fun " + env.functionName);
		}
		return new Sreturn(e);
	}

	@Override
	public void visit(Pstruct n, Environement env) {
		if (Environement.structs.containsKey(n.s)){
			throw new RuntimeException("Struct already exists");
		} else {
			Structure structure = new Structure(n.s);
			Environement.structs.put(n.s, new Tstruct(structure)); // Add the structure before typing the fields
			for (Pdeclvar pdeclvar : n.fl){
				if (structure.fields.containsKey(pdeclvar.id)){
					throw new RuntimeException("Two fields with the same name");
				} else {
					structure.fields.put(pdeclvar.id, new Field(pdeclvar.id, pdeclvar.typ.accept(this, env)));
				}
			}
		}
    }

	@Override
	public void visit(Pfun n, Environement env) {
		/*
		Mapping all arguments
		 */
		LinkedList<Decl_var> vars = new LinkedList<>();
		Set<String> argNames = new HashSet<>();
		for (Pdeclvar pdeclvar : n.pl){
			if (argNames.contains(pdeclvar.id)){
				throw new RuntimeException("Arguments of function " + n.s + " must have different names");
			} else {
				vars.add(new Decl_var(pdeclvar.typ.accept(this, env), pdeclvar.id));
				argNames.add(pdeclvar.id);
			}
		}

		/*
		 * Build the function and type its body
		 */
		Decl_fun decl_fun = new Decl_fun(n.ty.accept(this, env), n.s, vars, null);
		if (Environement.functions.containsKey(n.s)){
			throw new RuntimeException("Function " + n.s + " already defined");
		} else {
			Environement.functions.put(n.s, decl_fun);
			Environement environement = env.copy(n.ty.accept(this, env));
			vars.forEach(
					decl_var -> environement.locals.put(decl_var.name, decl_var.t)
			);
			Environement.functions.get(n.s).fun_body = n.b.accept(this, environement);
			file.funs.add(decl_fun);
		}
	}
}

class Environement{


	public static HashMap<String, Tstruct> structs = new HashMap<>();
	public static HashMap<String, Decl_fun> functions = new HashMap<>();

	public HashMap<String, Typ> locals;
	public Typ returnType;
	public String functionName = "DEBUG : NONE"; // for debug

	public Environement(Typ returnType) {
		this.returnType = returnType;
		this.locals = new HashMap<>();
	}

	private Environement(Typ returnType, HashMap<String, Typ> locals){
		this.returnType = returnType;
		this.locals = new HashMap<>();
		this.locals.putAll(locals);
	}

	Environement copy(Typ returnType){
		return new Environement(returnType, locals);
	}
}
