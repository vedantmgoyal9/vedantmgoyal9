package java_programs.for_loop;

import java.util.Scanner;

public class SumDigits {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. : ");
    int n = sc.nextInt();
    int i, s = 0;
    for (i = n; i != 0; i = i / 10) s = s + i % 10;
    System.out.print("Sum = " + s);
    sc.close();
  }
}
