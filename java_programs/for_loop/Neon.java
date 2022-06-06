package java_programs.for_loop;

import java.util.*;

class Neon {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    int n, sq, s = 0;
    System.out.print("enter a number : ");
    n = sc.nextInt();
    for (sq = n * n; sq != 0; sq = sq / 10) s = s + sq % 10;
    if (s == n) System.out.print("Neon");
    else System.out.print("Not Neon");
    sc.close();
  }
}
