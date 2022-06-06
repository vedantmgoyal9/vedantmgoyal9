package java_programs.constructors;
// ICSE 2016
import java.util.Scanner;

public class BookFair {
  static String Bname;
  static double price;

  BookFair() {
    Bname = null;
    price = 0.0;
  }

  private static void Input() {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter name of the book: ");
    Bname = sc.nextLine();
    System.out.println("Enter price of the book: ");
    price = sc.nextInt();
  }

  private static void calculate() {
    if (price <= 1000) price -= (0.02 * price);
    else if (price > 1000 && price <= 3000) price -= (0.1 * price);
    else price -= (0.15 * price);
  }

  private static void display() {
    System.out.println("Name of the book: " + Bname);
    System.out.println("Price of the book: " + price);
  }

  public static void main(String[] args) {
    BookFair object = new BookFair();
    object.Input();
    object.calculate();
    object.display();
  }
}
