package mini_c.RTL;

/** Register Transfer Language (RTL) */

import mini_c.RTL.instructs.Mbbranch;
import mini_c.RTL.instructs.Mbinop;
import mini_c.RTL.instructs.Mubranch;
import mini_c.RTL.instructs.Munop;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** le type des instructions RTL */
public abstract class RTL {
  public abstract void accept(RTLVisitor v);
  public abstract Label[] succ();
  }


