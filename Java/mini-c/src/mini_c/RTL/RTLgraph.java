package mini_c.RTL;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * graphe de flot de contrôle (d'une fonction)
 * <p>
 * c'est un dictionnaire qui associe une instruction de type RTL
 * à une étiquette de type Label
 */
public class RTLgraph {
    public Map<Label, RTL> graph = new HashMap<Label, RTL>();

    /**
     * ajoute une nouvelle instruction dans le graphe
     * et renvoie son étiquette
     */
    public Label add(RTL instr) {
        Label l = new Label();
        graph.put(l, instr);
        return l;
    }

    // imprime le graphe par un parcours en profondeur
    private void print(Set<Label> visited, Label l) {
        if (visited.contains(l)) return;
        visited.add(l);
        RTL r = this.graph.get(l);
        if (r == null) return; // c'est le cas pour exit
        System.out.println("  " + String.format("%3s", l) + ": " + r);
        for (Label s : r.succ()) print(visited, s);
    }

    /**
     * imprime le graphe (pour debugger)
     */
    public void print(Label entry) {
        print(new HashSet<Label>(), entry);
    }
}
