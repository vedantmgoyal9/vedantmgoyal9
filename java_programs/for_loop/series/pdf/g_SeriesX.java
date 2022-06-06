package java_programs.for_loop.series.pdf;

import java.util.*;
// G. 0,7, 26, 63.............. N TERMS.

class g_SeriesX {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), i, a;
    for (i = 1; i <= n; i++) {
      a = i * i * i - 1;
      System.out.print(a);
      if (i != n) System.out.print(", ");
    }
    sc.close();
  }
}
