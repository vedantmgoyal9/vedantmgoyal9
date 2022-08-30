package java_programs.series_for_loop;

import java.util.*;
// 1,2,4,7,11,16..........

class Series_1_2_4_7 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), a = 1;
    for (int i = 0; i < n; i++) {
      System.out.print(a += i);
      if (i != n - 1) System.out.print(", ");
    }
    sc.close();
  }
}
