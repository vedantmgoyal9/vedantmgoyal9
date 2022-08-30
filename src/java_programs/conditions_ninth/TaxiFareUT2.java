package java_programs.conditions_ninth;

import java.util.*;

/*
 * WAP to compute the amount that a customer pays for the taxi that he hires
 * based on the following conditions: [12]
 * Kms travelled          Amount per Km
 * First 10 kms                25
 * Next 20 kms                 10
 * Next 40 kms                 15
 * Above 70 kms                12
Input the taxi number & the number of kilometres travelled by him
 */
class TaxiFareUT2 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter Taxi Number : ");
    String taxiNo = sc.nextLine();
    System.out.print("Enter distance : ");
    double d = sc.nextDouble(), amt = 0;
    if (d <= 10) amt = d * 25;
    else if (d <= 30) amt = 250 + (d - 10) * 10;
    else if (d <= 70) amt = 250 + 200 + (d - 30) * 15;
    else amt = 250 + 200 + 600 + (d - 70) * 12;
    System.out.println("Taxi number : " + taxiNo);
    System.out.println("Distance : " + d);
    System.out.println("Payable Amount : " + amt);
    sc.close();
  }
}
