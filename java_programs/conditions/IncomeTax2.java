package java_programs.conditions;

import java.util.*;

/*      Income         Tax
 * Upto 180000         Nil.
 * 180001 to 300000    10%
 * 300001 to 800000    20%
 * 800001 and above    30%
 */
public class IncomeTax2 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter Annual Income : ");
    double inc = sc.nextDouble(), tax = 0;
    if (inc <= 180000) tax = 0;
    else if (inc > 180000 && inc <= 300000) tax = (inc - 180000) * 0.1;
    else if (inc > 300000 && inc <= 800000) tax = 12000 + (inc - 300000) * 0.2;
    else tax = 18000 + 100000 + (inc - 800000) * 0.3;
    System.out.println("Annual Income = " + inc);
    System.out.println("Income Tax  = " + tax);
    sc.close();
  }
}
