package java_programs.while_loop;

import java.util.*;

class SumPrimeDigitsWhileLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no. : ");
    int n = sc.nextInt(), s = 0;
    while (n > 0) {
      if (n % 10 == 2 || n % 10 == 3 || n % 10 == 5 || n % 10 == 7) s = s + n % 10;
      n = n / 10;
    }
    System.out.println("Sum of prime digits of a number : " + s);
    sc.close();
  }
}
