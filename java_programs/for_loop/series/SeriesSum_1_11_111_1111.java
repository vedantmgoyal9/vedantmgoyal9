package java_programs.for_loop.series;

import java.util.Scanner;

public class SeriesSum_1_11_111_1111 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), j = 1, s = 0;
    for (int i = 1; i <= n; i++) {
      s += j;
      j = j * 10 + 1;
    }
    System.out.println("Sum = " + s);
    sc.close();
  }
}
