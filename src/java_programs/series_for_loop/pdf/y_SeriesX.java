package java_programs.series_for_loop.pdf;

import java.util.Scanner;
// Y. (X^2)/2! - (X^4)/4! + (X^6)/6! - (X^8)/8!...................(X^N)/N!

public class y_SeriesX {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter X and no. of terms : ");
    int x = sc.nextInt(), n = sc.nextInt();
    double f = 1, s = 0;
    for (int i = 1; i <= n; i++, f = 1) {
      for (int findFactorial = 1; findFactorial <= (i * 2); findFactorial++) f *= findFactorial;
      if (i % 2 == 0) {
        s -= (Math.pow(x, i * 2) / f);
        System.out.print(" - " + x + "^" + (i * 2) + "/" + f);
      } else {
        s += (Math.pow(x, i * 2) / f);
        if (i != 1) System.out.print(" + ");
        System.out.print(x + "^" + (i * 2) + "/" + f);
      }
    }
    System.out.print("\nSum : " + s);
    sc.close();
  }
}
