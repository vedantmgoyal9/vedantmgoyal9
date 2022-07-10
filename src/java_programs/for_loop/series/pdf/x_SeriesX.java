package java_programs.for_loop.series.pdf;

import java.util.Scanner;
// X. X - (X^2)/2! + (X^3)/3! - (X^4)/4!...................(X^N)/N!

public class x_SeriesX {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter X and no. of terms : ");
    int x = sc.nextInt(), n = sc.nextInt();
    double f = 1, s = x;
    System.out.print(x);
    for (int i = 2; i <= n; i++) {
      f *= i;
      if (i % 2 == 0) {
        s -= (Math.pow(x, i) / f);
        System.out.print(" - " + x + "^" + i + "/" + f);
      } else {
        s += (Math.pow(x, i) / f);
        System.out.print(" + " + x + "^" + i + "/" + f);
      }
    }
    System.out.print("\nSum : " + s);
    sc.close();
  }
}
