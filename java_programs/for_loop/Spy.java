package java_programs.for_loop;

import java.util.*;

class Spy {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    int i, n, s = 0, p = 1;
    System.out.print("enter a number : ");
    n = sc.nextInt();
    for (i = n; i != 0; i = i / 10) {
      s = s + i % 10;
      p = p * (i % 10);
    }
    if (s == p) System.out.print("Spy");
    else System.out.print("Not Spy");
    sc.close();
  }
}
