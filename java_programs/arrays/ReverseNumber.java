package java_programs.arrays;

import java.util.Scanner;

public class ReverseNumber {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of blocks of array: ");
    int n = sc.nextInt(), arr[] = new int[n], r = 0, num = 0;
    for (int i = 0; i < n; i++) {
      System.out.println("Enter a no.: ");
      arr[i] = sc.nextInt();
    }
    for (int i = 0; i < n; i++, r = 0) {
      num = arr[i];
      while (num != 0) {
        r = r * 10 + num % 10;
        num /= 10;
      }
      System.out.println("Reverse of " + arr[i] + ": " + r);
    }
  }
}
