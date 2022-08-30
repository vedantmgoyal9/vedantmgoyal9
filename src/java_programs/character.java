package java_programs;

import java.util.*;

public class character {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a character : ");
    char ch = sc.next().charAt(0);
    if (ch >= 'a' && ch <= 'z') System.out.print(ch + " is a Small Letter");
    else if (ch > 47 && ch < 58) System.out.print(ch + " is a Digit");
    else if (ch >= 'A' && ch <= 'Z') System.out.print(ch + " is a Capitalised Letter");
    else System.out.print(ch + " is a Symbol");
    sc.close();
  }
}
