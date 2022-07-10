package java_programs.patterns;

import java.util.Scanner;

/*  1
    2 1
    3 2 1
    4 3 2 1
*/
public class NRTno1 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = 1; i <= lines; i++) {
      for (int j = i; j >= 1; j--) System.out.print(j + " ");
      System.out.println();
    }
    sc.close();
  }
}
