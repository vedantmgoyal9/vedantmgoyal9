package java_programs.patterns;

import java.util.Scanner;

/*  4
    4 3
    4 3 2
    4 3 2 1
*/
public class NRTno2 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = lines; i >= 1; i--) {
      for (int j = lines; j >= i; j--) System.out.print(j + " ");
      System.out.println();
    }
    sc.close();
  }
}
