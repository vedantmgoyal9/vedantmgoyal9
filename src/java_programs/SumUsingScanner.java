package java_programs;

import java.util.*;

class SumUsingScanner {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    int a, b;
    System.out.print("Enter 2 no. : ");
    a = sc.nextInt();
    b = sc.nextInt();
    System.out.print("Sum = " + (a + b));
    sc.close();
  }
}
