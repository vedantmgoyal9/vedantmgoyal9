package java_programs.for_loop;

import java.util.*;

class CountDigits {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. : ");
    int n = sc.nextInt();
    int i, c = 0;
    for (i = n; i != 0; i = i / 10) c++;
    System.out.print("DIGITS = " + c);
    sc.close();
  }
}
