package java_programs.numbers_logic;

import java.util.*;

class CycleDigitsForLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a number : ");
    int n = sc.nextInt(), t = n, c = 0, p;
    while (t != 0) {
      c++;
      t /= 10;
    }
    p = (int) Math.pow(10, c - 1);
    for (int i = 1; i <= c; i++) {
      System.out.println(n);
      n = (n % p) * 10 + n / p;
    }
    sc.close();
  }
}
