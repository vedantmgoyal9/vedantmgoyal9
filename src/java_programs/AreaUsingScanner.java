package java_programs;

import java.util.Scanner;

class AreaUsingScanner {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    double b, h;
    System.out.print("Enter base : ");
    b = sc.nextDouble();
    System.out.print("Enter height : ");
    h = sc.nextDouble();
    System.out.print("Area = " + 0.5 * b * h);
    sc.close();
  }
}
