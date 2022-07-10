package java_programs.constructors;
// ICSE 2017
import java.util.Scanner;

public class ElectricBill {
  static String n;
  static int units;
  static double bill;

  ElectricBill() {
    n = null;
    units = 0;
    bill = 0.0;
  }

  private static void accept() {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter name & number of units: ");
    n = sc.nextLine();
    units = sc.nextInt();
  }

  private static void calculate() {
    if (units <= 100) bill = units * 2;
    else if (units <= 300) bill = 200 + (units - 100) * 3;
    else {
      bill = 200 + 600 + (units - 300) * 5;
      bill = bill + bill * 2.5 / 100;
    }
  }

  private static void print() {
    System.out.println("Name of the customer: " + n);
    System.out.println("Number of units consumed: " + units);
    System.out.println("Bill Amount: " + bill);
  }

  public static void main(String[] args) {
    ElectricBill object = new ElectricBill();
    object.accept();
    object.calculate();
    object.print();
  }
}
