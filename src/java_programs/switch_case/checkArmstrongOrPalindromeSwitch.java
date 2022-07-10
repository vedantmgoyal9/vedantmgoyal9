package java_programs.switch_case;

import java.util.Scanner;

class checkArmstrongOrPalindromeSwitch {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a no : ");
    int n = sc.nextInt();
    System.out.println("Enter a choice:");
    System.out.println("1: for Armstrong");
    System.out.println("2: for Palindrome");
    int c = sc.nextInt(), t = n, x = 0;
    switch (c) {
      case 1:
        while (n != 0) {
          x = x + (n % 10) * (n % 10) * (n % 10);
          n = n / 10;
        }
        if (x == t) System.out.print("Armstrong number");
        else System.out.print("Not Armstrong number");
        break;
      case 2:
        while (n != 0) {
          x = x * 10 + n % 10;
          n = n / 10;
        }
        if (x == t) System.out.print("Palindrome number");
        else System.out.print("Not Palindrome number");
        break;
      default:
        System.out.print("Wrong Choice!");
        break;
    }
    sc.close();
  }
}
