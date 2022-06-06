package java_programs.nested_for_while_loop;

import java.util.*;

class ReverseUpperLowerNestedLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter upper & lower limits ");
    int u = sc.nextInt(), l = sc.nextInt(), i, r, t;
    for (i = l; i <= u; i++) {
      r = 0;
      t = i;
      while (t != 0) {
        r = r * 10 + t % 10;
        t = t / 10;
      }
      System.out.println("Reverse of " + i + " = " + r);
    }
    sc.close();
  }
}
