package java_programs.strings;

import java.util.Scanner;

// program to replace a vowel with the next vowel in alphabet
public class NextVowel {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a string: ");
    String s = sc.nextLine();
    for (int i = s.length(); i > 0; i--) {
      for (int j = 0; j < i; j++) System.out.print(s.charAt(j));
      System.out.println();
    }
    for (int i = s.length(); i > 0; i--) {
      System.out.println(s.substring(0, i));
    }
  }
}
