package java_programs.switch_case;

import java.util.Scanner;

class checkPrimeOrPerfectSwitch {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a no : ");
    int n = sc.nextInt();
    System.out.println("Enter a choice:");
    System.out.println("1: for Prime");
    System.out.println("2: for Perfect");
    int c = sc.nextInt(), i = 1, t = 0;
    switch (c) {
      case 1:
        while (i <= n) {
          if (n % i == 0) t++;
          i++;
        }
        if (t == 2) System.out.println("Prime");
        else System.out.println("Not Prime");
        break;
      case 2:
        for (i = 1; i < n; i++) if (n % i == 0) t = t + i;
        if (t == n) System.out.println(n + " is a Perfect Number");
        else System.out.println(n + " is NOT a Perfect Number");
        break;
      default:
        System.out.print("Wrong Choice!");
        break;
    }
    sc.close();
  }
}
