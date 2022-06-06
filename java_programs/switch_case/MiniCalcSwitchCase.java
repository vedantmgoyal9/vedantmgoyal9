package java_programs.switch_case;

import java.util.*;

class MiniCalcSwitchCase {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter 2 no .:");
    int a = sc.nextInt();
    int b = sc.nextInt();
    System.out.print("Enter +,-,* or/ ");
    char ch = sc.next().charAt(0);
    switch (ch) {
      case '+':
        System.out.print("SUM=" + (a + b));
        break;
      case '-':
        System.out.print("difference=" + (a - b));
        break;
      case '*':
        System.out.print("product=" + a * b);
        break;
      case '/':
        System.out.print("division=" + a / b);
        break;
      default:
        System.out.print("INVALID CHOICE");
        break;
    }
    sc.close();
  }
}
