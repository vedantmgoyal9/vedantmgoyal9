package java_programs.patterns.combined;

import java.util.Scanner;

public class b {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int n = sc.nextInt(), s = -1;
    for (int i = n; i >= 1; i--) {
      for (int j = 1; j <= i; j++) System.out.print(j + " ");
      for (int j = 1; j <= s; j++) System.out.print("  ");
      s = s + 2;
      for (int j = i == n ? n - 1 : i; j >= 1; j--) System.out.print(j + " ");
      System.out.println();
    }
    s = s - 4;
    for (int i = 2; i <= n; i++) {
      for (int j = 1; j <= i; j++) System.out.print(j + " ");
      for (int j = 1; j <= s; j++) System.out.print("  ");
      s = s - 2;
      for (int j = i == n ? n - 1 : i; j >= 1; j--) System.out.print(j + " ");
      System.out.println();
    }
    sc.close();
  }
}
