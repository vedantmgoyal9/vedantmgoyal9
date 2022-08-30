package java_programs.numbers_logic;

import java.util.Scanner;

public class Automorphic1_forLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    int n, i, p = 1;
    System.out.print("enter a number : ");
    n = sc.nextInt();
    for (i = n; i != 0; i = i / 10) p = p * 10;
    if ((n * n) % p == n) System.out.println("Automorphic number");
    else System.out.println("Not an Automorphic number");
    sc.close();
  }
}
