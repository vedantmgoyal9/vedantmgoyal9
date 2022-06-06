package java_programs.for_loop.series.pdf;

import java.util.Scanner;
// K nd O. S = 1 + X + X^2 + X^3 + .......................+ X^N

public class k_o_SeriesX {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter X and no. of terms : ");
    int x = sc.nextInt(), n = sc.nextInt(), sum = 1 + x;
    System.out.print(1 + " + " + x);
    for (int i = 2; i <= n - 1; i++) {
      sum += Math.pow(x, i);
      System.out.print(" + " + x + "^" + i);
    }
    System.out.println("\nSum : " + sum);
    sc.close();
  }
}
