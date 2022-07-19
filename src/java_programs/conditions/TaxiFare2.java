package java_programs.conditions;

import java.util.*;

/*
 * WAP to compute the amount that a customer pays for the taxi that he hires
 * based on the following conditions: [12]
 * Kms travelled          Amount per Km
 * Up to 5 kms                 25
 * 6 to 10 kms                  5
 * 11 to 20 kms                 4
 * 21 and above               10/5
Input the taxi number & the number of kilometres travelled by him
 */
class TaxiFare2 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter distance : ");
    int d = sc.nextInt();
    double f = 0;
    if (d <= 5) f = 25;
    else if (d <= 10) f = 25 + (d - 5) * 5;
    else if (d <= 20) f = 25 + 25 + (d - 10) * 4;
    else f = 90 + (Math.ceil((d - 20) / 5.0)) * 10;
    System.out.println("Fare for " + d + " km = " + f);
    sc.close();
  }
}
