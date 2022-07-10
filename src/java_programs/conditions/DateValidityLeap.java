// Write a program to enter date, month and year and check if it is valid or not.
package java_programs.conditions;

import java.util.*;

public class DateValidityLeap {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter date, month and year : ");
    int d = sc.nextInt();
    int m = sc.nextInt();
    int y = sc.nextInt();
    if (d <= 0 || m <= 0 || y <= 0 || d > 31 || m > 12) System.out.print("Invalid");
    else if ((m == 4 || m == 6 || m == 9 || m == 11) && d == 31) System.out.print("Invalid");
    else if (m == 2 && (y % 400 == 0 || (y % 100 != 0 && y % 4 == 0)) && d > 29)
      System.out.print("Invalid");
    else if (m == 2 && !(y % 400 == 0 || (y % 100 != 0 && y % 4 == 0)) && d > 28)
      System.out.print("Invalid");
    else System.out.print("Valid");
    sc.close();
  }
}
