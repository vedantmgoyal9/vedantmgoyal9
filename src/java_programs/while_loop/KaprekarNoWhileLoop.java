package java_programs.while_loop;

import java.util.*;

public class KaprekarNoWhileLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no. : ");
    int n = sc.nextInt(), t = n, a = 1;
    while (t != 0) {
      a = a * 10;
      t = t / 10;
    }
    t = n * n;
    if ((t % a) + (t / a) == n) System.out.print("The number " + n + " is a Kaprekar No. ");
    else System.out.print("The number " + n + " is not a Kaprekar No. ");
    sc.close();
  }
}
