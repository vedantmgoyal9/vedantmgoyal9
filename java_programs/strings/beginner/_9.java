package java_programs.strings.beginner;

import java.util.Scanner;

public class _9 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a string");
    String str = sc.nextLine();
    System.out.println("Reverse of the string is: ");
    for (int i = str.length() - 1; i >= 0; i--) {
      System.out.print(str.charAt(i));
    }
  }
}
