package java_programs;

import java.util.*;

public class Palindrome {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a number : ");
    int n = sc.nextInt();
    if (n / 100 == n % 10 % 10) System.out.print(n + " is a palindrome number.");
    else System.out.print(n + " is not a palindrome number.");
    sc.close();
  }
}
