package java_programs.numbers_logic;

import java.util.*;

class MiddleDigitWhileLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no. :- ");
    int n = sc.nextInt(), t = n, c = 0;
    while (t != 0) {
      c++;
      t = t / 10;
    }
    n = (n / ((int) Math.pow(10, c / 2)) % 10);
    System.out.print("Middle digit : " + n);
    sc.close();
  }
}
