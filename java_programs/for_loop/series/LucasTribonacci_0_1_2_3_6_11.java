package java_programs.for_loop.series;

import java.util.Scanner;

public class LucasTribonacci_0_1_2_3_6_11 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter number of terms : ");
    int n = sc.nextInt(), i, a = 0, b = 1, c = 2, d;
    for (i = 1; i <= n; i++) {
      System.out.print(a);
      if (i != n) System.out.print(", ");
      d = a + b + c;
      a = b;
      b = c;
      c = d;
    }
    sc.close();
  }
}
