package java_programs.nested_for_while_loop;

import java.util.*;

public class PrimeLimitNestedForLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a limit ");
    int l = sc.nextInt(), i, j, c;
    for (i = 1; i <= l; i++) {
      c = 0;
      for (j = 1; j <= i; j++) if (i % j == 0) c++;
      if (c == 2) System.out.println(i);
    }
  }
}
