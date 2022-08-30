package java_programs;

import java.util.Scanner;

public class LongestWord {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a sentence: ");
    String str = sc.nextLine().trim() + " ";
    String longestWord = "";
    for (int i = 0; i < str.length(); i++) {
      if (longestWord.length() <= str.substring(i, str.indexOf(" ", i)).length()) {
        longestWord = str.substring(i, str.indexOf(" ", i));
      }
    }
    System.out.println("Longest word is: " + longestWord);
  }
}
