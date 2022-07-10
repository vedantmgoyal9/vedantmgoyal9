package java_programs.strings.beginner;

import java.util.Scanner;

public class _5 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter first string: ");
    String str1 = sc.nextLine();
    System.out.println("Enter second string: ");
    System.out.print("The shorter string is: ");
    String str2 = sc.nextLine();
    if (str1.length() < str2.length()) {
      System.out.print(str1);
    } else {
      System.out.print(str2);
    }
  }
}
