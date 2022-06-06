package java_programs.patterns;

import java.util.Scanner;

public class TriangleMouldNo {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no. : ");
    int n = sc.nextInt(), s = -1;
    for (int i = n; i >= 1; i--) {
      for (int j = 1; j <= i; j++) System.out.print(j);
      for (int j = 1; j <= s; j++) System.out.print(" ");
      s += 2;
      for (int j = (i == n ? n - 1 : i); j >= 1; j--) System.out.print(j);
      System.out.println();
    }
    sc.close();
  }
}
