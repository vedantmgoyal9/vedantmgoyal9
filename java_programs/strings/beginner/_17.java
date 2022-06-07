package java_programs.strings.beginner;

import java.util.Scanner;

public class _17 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a sentence: ");
    String str = sc.nextLine().toLowerCase();
    for (int i = 0; i < str.length() - 1; i++)
      if (str.charAt(i) + 1 == str.charAt(i + 1) || str.charAt(i) - 1 == str.charAt(i + 1))
        System.out.println(str.charAt(i) + "" + str.charAt(i + 1));
  }
}
