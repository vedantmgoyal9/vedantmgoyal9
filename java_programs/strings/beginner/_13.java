package java_programs.strings.beginner;

import java.util.Scanner;

public class _13 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter your name: ");
    String name = " " + sc.nextLine().trim();
    for (int i = 0; i < name.lastIndexOf(' '); i++) {
      if (name.charAt(i) == ' ') System.out.print(Character.toUpperCase(name.charAt(i + 1)) + ". ");
    }
    System.out.print(
        Character.toUpperCase(name.charAt(name.lastIndexOf(' ') + 1))
            + name.substring(name.lastIndexOf(' ') + 2));
  }
}
