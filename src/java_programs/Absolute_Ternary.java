package java_programs;

import java.util.*;

public class Absolute_Ternary {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no. : ");
    double n = sc.nextDouble();
    System.out.print("Absolute value of " + n + " = " + (n < 0 ? -n : n));
    sc.close();
  }
}
