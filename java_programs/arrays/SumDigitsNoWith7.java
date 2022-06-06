package java_programs.arrays;

import java.util.Scanner;

public class SumDigitsNoWith7 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of blocks of array: ");
    int n = sc.nextInt(), arr[] = new int[n], s = 0, j = 0;
    for (int i = 0; i < n; i++) {
      System.out.println("Enter value for " + i + " block of array: ");
      arr[i] = sc.nextInt();
      for (j = arr[i]; j != 0; j = j / 10) if (j % 10 == 7) break;
      if (j != 0) for (int k = arr[i]; k != 0; k = k / 10) s += k % 10;
    }
    System.out.println("Displaying Sum of Digits of Numbers with 7: " + s);
  }
}
