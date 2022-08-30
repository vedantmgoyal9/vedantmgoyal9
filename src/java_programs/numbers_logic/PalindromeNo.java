package java_programs.numbers_logic;

import java.util.Scanner;

class PalindromeNo {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a no : ");
    int n = sc.nextInt(), t = n, r = 0;
    while (t != 0) {
      r = r * 10 + t % 10;
      t = t / 10;
    }
    if (r == t) System.out.print("Palindrome number");
    else System.out.print("Not Palindrome number");
    sc.close();
  }
}
