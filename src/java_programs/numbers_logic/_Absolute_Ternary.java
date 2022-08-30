package java_programs.numbers_logic;

import java.util.*;

public class _Absolute_Ternary {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no. : ");
    double n = sc.nextDouble();
    System.out.print("Absolute value of " + n + " = " + (n < 0 ? -n : n));
    sc.close();
  }
}
