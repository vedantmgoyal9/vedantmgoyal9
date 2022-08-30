package java_programs.series_for_loop.pdf;

import java.util.Scanner;
// J. S = 1/1! + 2/2! + 3/3! + ..........................+ N/N!

public class j_SeriesX {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt();
    double s = 0, f = 1;
    for (int i = 1; i <= n; i++) {
      f *= i;
      s += i / f;
      System.out.print(i + "/" + i + "!");
      if (i != n) System.out.print(" + ");
    }
    System.out.println("\nSum : " + s);
    sc.close();
  }
}
