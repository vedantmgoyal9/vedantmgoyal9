package java_programs.series_for_loop;

import java.util.*;

class Series_1_12_123 {
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
