package java_programs.for_loop.series.pdf;

import java.util.Scanner;
// E. 1, 12, 123, 1234, 12345............ N TERMS.

class e_SeriesX {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), i, a = 0;
    for (i = 1; i <= n; i++) {
      a = a * 10 + i;
      System.out.println(a);
    }
    sc.close();
  }
}
