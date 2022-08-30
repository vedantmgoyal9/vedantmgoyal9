package java_programs.conditions_ninth;

import java.util.*;

class GreatestOf3_Ternary {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter 3 numbers : ");
    int a = sc.nextInt(), b = sc.nextInt(), c = sc.nextInt();
    System.out.print("Greatest No. : " + (a > b && a > c ? a : (b > c ? b : c)));
    sc.close();
  }
}
