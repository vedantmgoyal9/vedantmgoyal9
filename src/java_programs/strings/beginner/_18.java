package java_programs.strings.beginner;

import java.util.Scanner;

public class _18 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a sentence: ");
    String str = sc.nextLine().trim() + " ", temp = "";
    for (int i = 0; i < str.length(); i++) {
      if (str.charAt(i) != ' ') {
        temp = str.charAt(i) + temp;
      } else {
        System.out.print(temp + " ");
        temp = "";
      }
    }
  }
}
