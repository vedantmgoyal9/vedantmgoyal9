package java_programs.nested_for_while_loop;

import java.util.*;

class MagicNoNestedWhileLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a number : ");
    int n = sc.nextInt();
    while (n > 9) {
      int s = 0;
      while (n > 0) {
        s = s + n % 10;
        n = n / 10;
      }
      n = s;
    }
    if (n == 1) System.out.print("Magic number");
    else System.out.print("Not a magic number");
    sc.close();
  }
}
