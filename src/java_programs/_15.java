package java_programs;

import java.util.Scanner;

public class _15 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a sentence: ");
    String str = sc.nextLine();
    String vowels = "aeiouAEIOU";
    for (int i = 0; i < str.length() - 1; i++)
      if (vowels.indexOf(str.charAt(i)) != -1 && vowels.indexOf(str.charAt(i + 1)) != -1)
        System.out.println(str.charAt(i) + "" + str.charAt(i + 1));
  }
}
