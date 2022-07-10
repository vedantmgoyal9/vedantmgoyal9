package java_programs.arrays;

import java.util.Scanner;

public class MultiplyPalindrome {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of blocks of array: ");
    int n = sc.nextInt(), arr[] = new int[n], r = 0, p = 1;
    for (int i = 0; i < n; i++, r = 0) {
      System.out.println("Enter value for " + i + " block of array: ");
      arr[i] = sc.nextInt();
      int t = arr[i];
      while (t != 0) {
        r = r * 10 + t % 10;
        t = t / 10;
      }
      if (r == arr[i]) p *= r;
    }
    System.out.println("Product of Palindrome Numbers: " + p);
  }
}
