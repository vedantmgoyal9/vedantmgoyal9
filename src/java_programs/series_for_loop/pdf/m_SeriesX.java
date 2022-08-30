package java_programs.series_for_loop.pdf;

import java.util.Scanner;
// M. S = 1 - X^2/2! + X^3/3! - X^4/4! ..................... + X^N/N!

public class m_SeriesX {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter X and no. of terms : ");
    int x = sc.nextInt(), n = sc.nextInt();
    double f = 1, s = 1;
    System.out.print("1");
    for (int i = 2; i <= n; i++) {
      f *= i;
      if (i % 2 == 0) {
        s -= (Math.pow(x, i)) / f;
        System.out.print(" - " + x + "^" + i + "/" + f);
      } else {
        s += (Math.pow(x, i)) / f;
        System.out.print(" + " + x + "^" + i + "/" + f);
      }
    }
    System.out.println("\nSum : " + s);
    sc.close();
  }
}
