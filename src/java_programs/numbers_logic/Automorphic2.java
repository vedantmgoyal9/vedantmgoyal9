package java_programs.numbers_logic;

import java.util.*;

class Automorphic2 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no. : ");
    int n = sc.nextInt(), p = 1, t = n;
    while (n != 0) {
      p = p * 10;
      n = n / 10;
    }
    if ((t * t) % p == t) System.out.println("Automorphic");
    else System.out.println("Not Automorphic");
    sc.close();
  }
}
