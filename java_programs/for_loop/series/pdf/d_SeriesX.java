package java_programs.for_loop.series.pdf;

import java.util.Scanner;
// d. 1 , 11,111,1111,11111......... N TERMS.

public class d_SeriesX {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), a = 0;
    for (int i = 1; i <= n; i++) {
      a = a * 10 + 1;
      System.out.println(a);
    }
    sc.close();
  }
}
