package java_programs.for_loop;

import java.util.*;

class OddNoSum {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a number : ");
    int i, sum = 0, n = sc.nextInt();
    for (i = 1; i <= n; i += 2) {
      System.out.println(i);
      sum += i;
    }
    System.out.println("Sum : " + sum);
    sc.close();
  }
}
