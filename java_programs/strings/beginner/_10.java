package java_programs.strings.beginner;

import java.util.Scanner;

public class _10 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a sentence: ");
    String str = sc.nextLine();
    str = str.trim();
    int noOfWords = 0;
    for (int i = 0; i < str.length(); i++) if (str.charAt(i) == ' ') noOfWords++;
    System.out.println("Number of words in the sentence: " + (noOfWords + 1));
  }
}
