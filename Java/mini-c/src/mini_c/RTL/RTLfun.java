package mini_c.RTL;


import mini_c.RTL.rtl_instructs.Register;

import java.util.*;

/** une fonction RTL */

public class RTLfun {
    /** nom de la fonction */
    public String name;
    /** paramètres formels */
    public List<Register> formals;
    /** résultat de la fonction */
    public Register result;
    /** ensemble des variables locales */
    public Set<Register> locals;
    /** point d'entrée dans le graphe */
    public Label entry;
    /** point de sortie dans le graphe */
    public Label exit;
    /** le graphe de flot de contrôle */
    public RTLgraph body;

    public RTLfun(String name) {
        this.name = name;
        this.formals = new LinkedList<>();
        this.locals = new HashSet<>();
    }

    void accept(RTLVisitor v) { v.visit(this); }

    /** pour débugger */
    void print() {
        System.out.println("== RTL ==========================");
        System.out.println(result + " " + name + formals);
        System.out.println("  entry  : " + entry);
        System.out.println("  exit   : " + exit);
        System.out.println("  locals : " + locals);
        body.print(entry);
    }
}
