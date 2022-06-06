package java_programs.strings.beginner;

import java.util.Scanner;

public class _8 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a string: ");
    String str = sc.nextLine();
    System.out.println("String in opposite case: ");
    for (int i = 0; i < str.length(); i++) {
      if (str.charAt(i) >= 'a' && str.charAt(i) <= 'z')
        System.out.print(Character.toUpperCase(str.charAt(i)));
      else if (str.charAt(i) >= 'A' && str.charAt(i) <= 'Z')
        System.out.print(Character.toLowerCase(str.charAt(i)));
      else System.out.print(str.charAt(i));
    }
  }
}
