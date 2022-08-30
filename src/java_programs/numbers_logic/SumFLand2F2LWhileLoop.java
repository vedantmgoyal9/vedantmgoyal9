package java_programs.numbers_logic;

import java.util.*;

public class SumFLand2F2LWhileLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a even-digited no : ");
    int n = sc.nextInt(), c = 0, r = 0, t = n;
    while (t != 0) {
      c++;
      t /= 10;
    }
    for (t = n; t != 0; t /= 10) r = r * 10 + t % 10;
    while (c != 0) {
      System.out.println(n % 10 + "+" + r % 10 + "=" + (n % 10 + r % 10));
      n /= 10;
      r /= 10;
      c = c - 2;
    }
    sc.close();
  }
}
