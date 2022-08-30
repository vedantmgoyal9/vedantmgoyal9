package java_programs.series_for_loop.pdf;

import java.util.Scanner;

class u_SeriesX_Fibonacci {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter number of terms : ");
    int n = sc.nextInt(), a = 0, b = 1, c;
    for (int i = 1; i <= n; i++) {
      System.out.print(a);
      if (i != n) System.out.print(", ");
      c = a + b;
      a = b;
      b = c;
    }
    sc.close();
  }
}
