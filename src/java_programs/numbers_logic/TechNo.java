package java_programs.numbers_logic;

import java.util.Scanner;

/*
 *  If the given number has an even number of digits and the number can be divided exactly
 *  into two parts from the middle.
 *  After equally dividing the number, sum up the numbers and find the square of the sum.
 *  If we get the number itself as square, the given number is a tech number, else, not a tech number.
 *  For example, 3025 is a tech number.
 */
public class TechNo {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a number : ");
    int n = sc.nextInt(), c = 0, t = n;
    while (t != 0) {
      c++;
      t /= 10;
    }
    if (c % 2 == 0
        && (int) Math.pow((n / (int) Math.pow(10, c / 2)) + (n % (int) Math.pow(10, c / 2)), 2)
            == n) System.out.println(n + " is a tech number");
    else System.out.println(n + " is not a tech number");
    sc.close();
  }
}
