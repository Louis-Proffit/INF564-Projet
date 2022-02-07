package mini_c.RTL;

import java.util.HashMap;

/** Un modèle mémoire minimal pour RTLinterp */

public class Memory {

  /** ici toutes les valeurs sont des entiers 64 bits
   *  représentées par le type long de Java */
  static final int word_size = 8;

  private long sbrk = 8l;
  private HashMap<Long, Long[]> mem = new HashMap<>();

  public Memory() {}

  /** alloue n octets */
  public long malloc(int n) {
    if (n < 0 || n % word_size != 0) throw new Error("malloc: invalid argument");
    long p = sbrk;
    sbrk += n;
    mem.put(p, new Long[n / word_size]);
    return p;
  }

  private int index(Long[] b, int ofs) {
    if (ofs % word_size != 0) throw new Error("pointer not aligned");
    int i = ofs / word_size;
    if (i < 0 || i >= b.length) throw new Error("access out of bounds");
    return i;
  }

  private void seg_fault() { throw new Error("seg fault"); }

  public long get(long ptr, int ofs) {
    Long[] b = mem.get(ptr);
    if (b == null) seg_fault();
    int i = index(b, ofs);
    return b[i];
  }

  public void set(long ptr, int ofs, long v) {
    Long[] b = mem.get(ptr);
    if (b == null) seg_fault();
    int i = index(b, ofs);
    b[i] = v;
  }
}
