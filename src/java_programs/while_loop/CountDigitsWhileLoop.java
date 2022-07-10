package java_programs.while_loop;

import java.util.*;

class CountDigitsWhileLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no : ");
    int n = sc.nextInt(), c = 0;
    if (n == 0) c = 1;
    else {
      while (n != 0) {
        c++;
        n /= 10;
      }
    }
    System.out.println("Number of digits = " + c);
    sc.close();
  }
}
