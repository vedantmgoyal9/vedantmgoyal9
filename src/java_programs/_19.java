package java_programs;

import java.util.Scanner;

public class _19 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a string: ");
    String str = " " + sc.nextLine().trim(), temp = "";
    for (int i = str.length() - 1; i >= 0; i--) {
      if (str.charAt(i) != ' ') {
        temp = str.charAt(i) + temp;
      } else {
        System.out.print(temp + " ");
        temp = "";
      }
    }
  }
}
