package java_programs.series_for_loop.pdf;

import java.util.Scanner;
// H. 1!, 2!, 3!..................... N TERMS.

public class h_SeriesX {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt();
    for (int i = 1; i <= n; i++) {
      int f = 1;
      for (int findFactorial = 1; findFactorial <= i; findFactorial++) f *= findFactorial;
      System.out.print(f);
      if (i != n) System.out.print(", ");
    }
    sc.close();
  }
}
