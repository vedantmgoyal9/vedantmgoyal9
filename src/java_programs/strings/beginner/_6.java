package java_programs.strings.beginner;

import java.util.Scanner;

public class _6 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a string: ");
    String str = sc.nextLine();
    System.out.println("Vowels in the string are: ");
    for (int i = 0; i < str.length(); i++) {
      if (str.charAt(i) == 'a'
          || str.charAt(i) == 'e'
          || str.charAt(i) == 'i'
          || str.charAt(i) == 'o'
          || str.charAt(i) == 'u'
          || str.charAt(i) == 'A'
          || str.charAt(i) == 'E'
          || str.charAt(i) == 'I'
          || str.charAt(i) == 'O'
          || str.charAt(i) == 'U') {
        System.out.print(str.charAt(i) + " ");
      }
    }
  }
}
