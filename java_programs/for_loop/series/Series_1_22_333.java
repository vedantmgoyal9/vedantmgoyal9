package java_programs.for_loop.series;

import java.util.*;

public class Series_1_22_333 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), a = 0;
    for (int i = 1; i <= n; i++) {
      a = a * 10 + 1;
      System.out.println(a * i);
    }
    sc.close();
  }
}
