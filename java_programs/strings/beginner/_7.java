package java_programs.strings.beginner;

import java.util.Scanner;

public class _7 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a string: ");
    String str = sc.nextLine();
    int a = 0, d = 0, s = 0;
    for (int i = 0; i < str.length(); i++) {
      if ((str.charAt(i) >= 'a' && str.charAt(i) <= 'z')
          || (str.charAt(i) >= 'A' && str.charAt(i) <= 'Z')) a++;
      else if (str.charAt(i) >= '0' && str.charAt(i) <= '9') d++;
      else s++;
    }
    System.out.println("Number of alphabets: " + a);
    System.out.println("Number of digits: " + d);
    System.out.println("Number of special characters: " + s);
  }
}
