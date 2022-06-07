package java_programs.strings;

import java.util.Scanner;

public class FrequencyOfWord {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a string: ");
    String str = sc.nextLine().toLowerCase().trim() + " ", word = "";
    System.out.println("Enter a word to find its frequency: ");
    String wordToFind = sc.nextLine().toLowerCase();
    int count = 0;
    for (int i = 0; i < str.length(); i++) {
      if (str.charAt(i) != ' ') word += str.charAt(i);
      else {
        if (word.equals(wordToFind) && !word.equals("")) count++;
        word = "";
      }
    }
    System.out.println("Frequency of word: " + count);
  }
}
