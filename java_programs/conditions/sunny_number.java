package java_programs.conditions;

import java.util.Scanner;

/*
 *  A number is called a sunny number if the number next to the given number is a perfect square.
 *  In other words, a number N will be a sunny number if N+1 is a perfect square.
 */
public class sunny_number {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a no. : ");
    int n = sc.nextInt();
    if (Math.sqrt(n + 1) - Math.floor(Math.sqrt(n + 1)) == 0) System.out.println("Sunny Number");
    else System.out.println("Not a Sunny Number");
    sc.close();
  }
}
