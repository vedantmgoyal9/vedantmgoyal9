package java_programs.while_loop;

import java.util.*;

class ImpSumDigitsWhileLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no : ");
    int n = sc.nextInt(), s = 0;
    while (n != 0) {
      s += n % 10;
      n = n / 10;
    }
    System.out.println("Sum of digits = " + s);
    sc.close();
  }
}
