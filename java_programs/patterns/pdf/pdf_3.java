package java_programs.patterns.pdf;

import java.util.Scanner;

/*  1
    22
    333
    4444
*/
public class pdf_3 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = 1; i <= lines; ++i) {
      for (int j = 1; j <= i; ++j) {
        System.out.print(i);
      }
      System.out.println();
    }
    sc.close();
  }
}
