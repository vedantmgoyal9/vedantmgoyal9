package java_programs.arrays;

import java.util.Scanner;

public class SumNumbers {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of blocks of array: ");
    int n = sc.nextInt(), arr[] = new int[n], s = 0;
    for (int i = 0; i < n; i++) {
      System.out.println("Enter a no.: ");
      arr[i] = sc.nextInt();
      s += arr[i];
    }
    System.out.println("Sum of elements in array: " + s);
  }
}
