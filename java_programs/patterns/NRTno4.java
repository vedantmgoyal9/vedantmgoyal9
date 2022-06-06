package java_programs.patterns;

import java.util.Scanner;

/*  0
    0 2
    0 2 4
    0 2 4 6
*/
public class NRTno4 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = 1; i <= lines; i++) {
      for (int j = 0; j < i; j++) System.out.print(j * 2 + " ");
      System.out.println();
    }
  }
}
