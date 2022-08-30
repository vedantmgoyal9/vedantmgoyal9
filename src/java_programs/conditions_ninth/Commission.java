package java_programs.conditions_ninth;

import java.util.*;

/*
 * Write a program to input monthly sale of a sales person and calculate
 * commission according to given slab:
 *      Sale                    Commission
 * Up to Rs. 100000               nil
 * Rs. 100001 to Rs. 200000        2%
 * Rs. 200001 to Rs. 500000        3%
 * Rs. 500001 and above            5%
 */
class Commission {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter monthly sale : ");
    double s = sc.nextDouble(), c;
    if (s <= 100000) c = 0;
    else if (s <= 200000) c = s * 0.02;
    else if (s <= 500000) c = s * 0.03;
    else c = s * 0.05;
    System.out.println("Sale = " + s);
    System.out.println("Commission  = " + c);
    sc.close();
  }
}
