package java_programs.for_loop;

import java.util.Scanner;
// a number whose all digits are odd.

public class corona_number {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a no. : ");
    int n = sc.nextInt();
    boolean areAllDigitsOdd = true;
    while (n != 0) {
      if ((n % 10) % 2 == 0) {
        areAllDigitsOdd = false;
        break;
      }
      n = n / 10;
    }
    if (areAllDigitsOdd) System.out.println("Corona Number");
    else System.out.println("Not a Corona Number");
    sc.close();
  }
}
