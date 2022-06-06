package java_programs.conditions;

import java.util.*;

public class LeapYear {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a year : ");
    int y = sc.nextInt();
    if (y % 400 == 0 || (y % 4 == 0 && y % 100 != 0)) System.out.print(y + " is a leap year");
    else System.out.print(y + " is not a leap year");
    sc.close();
  }
}
