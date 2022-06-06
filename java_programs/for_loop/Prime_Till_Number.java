package java_programs.for_loop;

import java.util.Scanner;

public class Prime_Till_Number {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no. : ");
    int n = sc.nextInt(), c = 0;
    for (int i = 1; i <= n; i++, c = 0) {
      for (int j = 1; j <= i; j++) if (i % j == 0) c++;
      if (c == 2) System.out.println(i);
    }
    sc.close();
  }
}
