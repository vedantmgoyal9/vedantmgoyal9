package java_programs.arrays;

import java.util.Scanner;

public class DisplayNoWith7 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of blocks of array: ");
    int n = sc.nextInt(), arr[] = new int[n];
    for (int i = 0; i < n; i++) {
      System.out.println("Enter value for " + i + " block of array: ");
      arr[i] = sc.nextInt();
    }
    System.out.println("Displaying Numbers with 7:");
    for (int j = 0; j < n; j++) {
      for (int k = arr[j]; k != 0; k = k / 10)
        if (k % 10 == 7) {
          System.out.println(arr[j]);
          break;
        }
    }
  }
}
