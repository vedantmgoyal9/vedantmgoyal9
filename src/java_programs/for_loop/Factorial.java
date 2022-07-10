package java_programs.for_loop;

import java.util.*;

class Factorial {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a No. : ");
    double n = sc.nextInt(), i, f = 1;
    for (i = 1; i <= n; i++) f = f * i;
    System.out.println("Factorial of " + n + " = " + f);
    sc.close();
  }
}
