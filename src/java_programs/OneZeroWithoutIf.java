package java_programs;

import java.util.*;

class OneZeroWithoutIf {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter 0 or 1 : ");
    int n = sc.nextInt();
    System.out.print(1 - n);
    sc.close();
  }
}
