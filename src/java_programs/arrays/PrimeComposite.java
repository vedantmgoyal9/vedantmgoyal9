package java_programs.arrays;

import java.util.Scanner;

public class PrimeComposite {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of blocks of array: ");
    int n = sc.nextInt(), arr[] = new int[n], c = 0;
    for (int i = 0; i < n; i++, c = 0) {
      System.out.println("Enter value for " + i + " block of array: ");
      arr[i] = sc.nextInt();
      for (int j = 1; j <= arr[i]; j++) {
        if (arr[i] % j == 0) c++;
      }
      if (c == 2) System.out.println("Prime");
      else if (c == 1) System.out.println("Neither Prime nor Composite");
      else System.out.println("Composite");
    }
  }
}
