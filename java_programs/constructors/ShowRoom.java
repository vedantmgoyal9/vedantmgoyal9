package java_programs.constructors;
// ICSE 2019
import java.util.Scanner;

public class ShowRoom {
  static String name;
  static long mobno;
  static double cost;
  static double dis;
  static double amount;

  ShowRoom() {
    name = null;
    mobno = 0;
    cost = 0.0;
    dis = 0.0;
    amount = 0.0;
  }

  private static void input() {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter your name: ");
    name = sc.nextLine();
    System.out.println("Enter your mobile number: ");
    mobno = sc.nextLong();
    System.out.println("Enter the cost of items purchased: ");
    cost = sc.nextDouble();
  }

  private static void calculate() {
    if (cost <= 10000) dis = 0.05 * cost;
    else if (cost > 10000 && cost <= 20000) dis = 0.1 * cost;
    else if (cost > 20000 && cost <= 35000) dis = 0.15 * cost;
    else dis = 0.2 * cost;
    amount = cost - dis;
  }

  private static void display() {
    System.out.println("Name of the customer: " + name);
    System.out.println("Mobile number: " + mobno);
    System.out.println("Amount to be paid after discount: " + amount);
  }

  public static void main(String[] args) {
    ShowRoom object = new ShowRoom();
    object.input();
    object.calculate();
    object.display();
  }
}
