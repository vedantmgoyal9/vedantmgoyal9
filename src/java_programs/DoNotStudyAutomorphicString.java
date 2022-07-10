package java_programs;

import java.util.Scanner;

public class DoNotStudyAutomorphicString {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a number : ");
    int n = sc.nextInt();
    int sq_n = n * n;

    String str_n = Integer.toString(n);
    String square = Integer.toString(sq_n);

    if (square.endsWith(str_n)) System.out.println("Automorphic Number.");
    else System.out.println("Not an Automorphic Number.");
    sc.close();
  }
}
