package java_programs.arrays;

import java.util.Scanner;

public class DisplayBuzz {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of blocks of array: ");
    int n = sc.nextInt(), arr[] = new int[n];
    for (int i = 0; i < n; i++) {
      System.out.println("Enter value for " + i + " block of array: ");
      arr[i] = sc.nextInt();
    }
    System.out.println("Displaying Buzz Numbers:");
    for (int j = 0; j < n; j++) {
      if (arr[j] % 10 == 7 || arr[j] % 7 == 0) System.out.println(arr[j]);
    }
  }
}
