package java_programs;

import java.util.*;

class IfAbsoluteWithoutMathAbs {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. : ");
    double n = sc.nextDouble();
    System.out.print("Absolute value of " + n + " = ");
    if (n < 0) n = -n;
    System.out.print(n);
    sc.close();
  }
}
