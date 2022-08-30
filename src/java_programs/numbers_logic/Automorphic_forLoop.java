package java_programs.numbers_logic;

import java.util.Scanner;

class Automorphic_forLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    int n, i, c = 0;
    System.out.print("enter a number : ");
    n = sc.nextInt();
    for (i = n; i != 0; i = i / 10) c++;
    c = (int) Math.pow(10, c);
    if ((n * n) % c == n) System.out.println("Automorphic number");
    else System.out.println("Not an Automorphic number");
    sc.close();
  }
}
