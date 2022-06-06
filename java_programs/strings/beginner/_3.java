package java_programs.strings.beginner;

import java.util.Scanner;

public class _3 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter first string");
    String s1 = sc.nextLine();
    System.out.println("Enter second string");
    String s2 = sc.nextLine();
    if (s1.length() == s2.length()) {
      System.out.println("Strings are equal");
    } else {
      System.out.println("Strings are not equal");
    }
  }
}
