package java_programs;

import java.util.*;

class DetailUsingScanner {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    String name;
    int std, age;
    char sec;
    double height;
    System.out.print("Enter name : ");
    name = sc.nextLine();
    System.out.print("Enter age : ");
    age = sc.nextInt();
    System.out.print("Enter class : ");
    std = sc.nextInt();
    System.out.print("Enter section : ");
    sc.nextLine();
    sec = sc.nextLine().charAt(0);
    System.out.print("Enter height : ");
    height = sc.nextDouble();
    System.out.println("Name\t: " + name);
    System.out.println("Age\t: " + age);
    System.out.println("Class\t: " + std);
    System.out.println("Section\t: " + sec);
    System.out.println("Height\t: " + height);
    sc.close();
  }
}
