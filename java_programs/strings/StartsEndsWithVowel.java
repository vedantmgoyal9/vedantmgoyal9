package java_programs.strings;

import java.util.Scanner;

public class StartsEndsWithVowel {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter number of strings to be entered");
    String[] arr = new String[sc.nextInt()];
    int count = 0;
    for (int i = 0; i < arr.length; i++) {
      System.out.println("Enter string " + i + ": ");
      arr[i] = sc.next();
    }
    for (int i = 0; i < arr.length; i++) {
      if (arr[i].matches("^[aAeEiIoOuU].*[aAeEiIoOuU]$")) {
        count++;
      }
    }
    System.out.println("Number of strings starting and ending with vowel is: " + count);
  }
}
