package java_programs.conditions;

import java.util.Scanner;

class Buzz {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. : ");
    int n = sc.nextInt();
    if (n % 7 == 0) System.out.print(n + " is a buzz number");
    else System.out.print(n + " is not a buzz number");
    sc.close();
  }
}
