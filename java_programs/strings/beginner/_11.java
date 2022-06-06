package java_programs.strings.beginner;

import java.util.Scanner;

public class _11 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a sentence: ");
    String str = sc.nextLine();
    str = str.trim();
    int noOfWords = 0;
    boolean wasPrevSpace = false;
    for (int i = 0; i < str.length(); i++) {
      if (str.charAt(i) == ' ' && !wasPrevSpace) {
        noOfWords++;
        wasPrevSpace = true;
      } else if (str.charAt(i) != ' ') {
        wasPrevSpace = false;
      }
    }
    System.out.println("Number of words: " + (noOfWords + 1));
  }
}
