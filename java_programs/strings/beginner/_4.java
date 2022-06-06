package java_programs.strings.beginner;

import java.util.Scanner;

public class _4 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a string: ");
    String str = sc.nextLine();
    for (int i = 0; i < str.length(); i++) {
      System.out.println(str.charAt(i));
    }
  }
}
