package java_programs.while_loop;

import java.util.*;

class PrimeNoWhileLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no. : ");
    int n = sc.nextInt(), i = 1, c = 0;
    while (i <= n) {
      if (n % i == 0) c++;
      i++;
    }
    if (c == 2) System.out.println("Prime");
    else System.out.println("Not Prime");
    sc.close();
  }
}
