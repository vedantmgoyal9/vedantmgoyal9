package java_programs.for_loop;

import java.util.*;

class PerfectNo {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no. : ");
    int n = sc.nextInt(), i, s = 0;
    for (i = 1; i < n; i++) if (n % i == 0) s = s + i;
    if (s == n) System.out.println(s + " is a Perfect Number");
    else System.out.println(s + " is NOT a Perfect Number");
    sc.close();
  }
}
