package java_programs.for_loop;

import java.util.*;

class FactorsSum {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no. : ");
    int n = sc.nextInt(), i, s = 0;
    System.out.println("Factors are:");
    for (i = 1; i <= n; i++)
      if (n % i == 0) {
        System.out.println(i);
        s = s + i;
      }
    System.out.println("Sum of factors are : " + s);
    sc.close();
  }
}
