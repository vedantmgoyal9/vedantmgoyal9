package java_programs.for_loop.series;

import java.text.DecimalFormat;
import java.util.Scanner;

class Series_5_7pt5_10 {
  public static void main(String[] args) {
    DecimalFormat rmDecZero = new DecimalFormat("0.#"); // removing zero after decimal
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt();
    double a = 5;
    for (int i = 1; i <= n; i++, a += 2.5) {
      System.out.print(rmDecZero.format(a)); // print w/o zero after decimal
      if (i != n) System.out.print(", ");
    }
    sc.close();
  }
}
