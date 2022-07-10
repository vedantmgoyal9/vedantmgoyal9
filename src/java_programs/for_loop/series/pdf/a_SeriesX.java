package java_programs.for_loop.series.pdf;

import java.util.Scanner;
// A. 3^3 + 4^4 + 5^5 .....................N^N

public class a_SeriesX {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), s = 0;
    for (int i = 3; i <= (n + 2); i++) {
      s += Math.pow(i, i);
      if (i != 3) System.out.print(" + ");
      System.out.print(i + "^" + i);
    }
    System.out.print("\nSum : " + s);
    sc.close();
  }
}
