package java_programs.patterns.diamond;

import java.util.Scanner;

public class BarfiStar {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = 1; i <= lines; i++) {
      for (int j = lines; j > i; j--) System.out.print("  ");
      for (int j = 1; j <= i; j++) System.out.print("* ");
      for (int j = 2; j <= i; j++) System.out.print("* ");
      System.out.println();
    }
    for (int i = lines - 1; i >= 1; i--) {
      for (int j = lines - 1; j > i - 1; j--) System.out.print("  ");
      for (int j = 1; j <= i; j++) System.out.print("* ");
      for (int j = 1; j <= i - 1; j++) System.out.print("* ");
      System.out.println();
    }
    sc.close();
  }
}
