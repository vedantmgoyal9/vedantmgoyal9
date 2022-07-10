package java_programs.for_loop;

import java.util.*;

class ReverseDigits {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. : ");
    int n = sc.nextInt(), i, r = 0;
    for (i = n; i != 0; i = i / 10) r = r * 10 + i % 10;
    System.out.print("Reverse = " + r);
    sc.close();
  }
}
