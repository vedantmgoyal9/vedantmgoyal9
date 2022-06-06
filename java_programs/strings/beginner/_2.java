package java_programs.strings.beginner;

import java.util.Scanner;

public class _2 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a string:");
    String str = sc.nextLine();
    System.out.println("No. of characters in the string: " + str.length());
  }
}
