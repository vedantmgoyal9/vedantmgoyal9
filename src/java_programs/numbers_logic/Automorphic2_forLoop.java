package java_programs.numbers_logic;

import java.util.*;

class Automorphic2_forLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    int i, n, s;
    System.out.print("enter a number : ");
    n = sc.nextInt();
    s = n * n;
    for (i = n; i != 0; i = i / 10)
      if (i % 10 != s % 10) break;
      else s = s / 10;
    if (i == 0) System.out.println("Automorphic number");
    else System.out.println("Not an Automorphic number");
    sc.close();
  }
}
