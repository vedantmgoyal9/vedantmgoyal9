package java_programs;

import java.util.*;

class Fibonacci {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter number of terms : ");
    int n = sc.nextInt(), i, a = 0, b = 1, c;
    for (i = 1; i <= n; i++) {
      System.out.println(a);
      c = a + b;
      a = b;
      b = c;
    }
    sc.close();
  }
}
