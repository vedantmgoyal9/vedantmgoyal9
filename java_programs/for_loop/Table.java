package java_programs.for_loop;

import java.util.*;

class Table {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("enter a number");
    int n = sc.nextInt();
    for (int i = 1; i <= 10; i++) System.out.println(n + " * " + i + " = " + n * i);
    sc.close();
  }
}
