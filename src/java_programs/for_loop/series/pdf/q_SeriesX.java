package java_programs.for_loop.series.pdf;

import java.util.Scanner;
// Q. 1,8,27,64,125...............N TERMS

public class q_SeriesX {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt();
    for (int i = 1; i <= n; i++) {
      if (i != 1) System.out.print(", ");
      System.out.print(i * i * i);
    }
    sc.close();
  }
}
