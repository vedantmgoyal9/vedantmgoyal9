package java_programs.while_loop;

import java.util.Scanner;

class Prime {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a no : ");
    int n = sc.nextInt(), i = 1, t = 0;
    while (i <= n) {
      if (n % i == 0) t++;
      i++;
    }
    if (t == 2) System.out.println("Prime");
    else System.out.println("Not Prime");
    sc.close();
  }
}
