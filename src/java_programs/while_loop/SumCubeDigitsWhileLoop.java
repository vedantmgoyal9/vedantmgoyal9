package java_programs.while_loop;

import java.util.*;

public class SumCubeDigitsWhileLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no : ");
    int n = sc.nextInt(), s = 0;
    while (n != 0) {
      s += (int) Math.pow(n % 10, 3);
      n = n / 10;
    }
    System.out.println("Sum of the cube of digits = " + s);
    sc.close();
  }
}
