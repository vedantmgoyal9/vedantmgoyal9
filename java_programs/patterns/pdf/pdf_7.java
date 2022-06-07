package java_programs.patterns.pdf;

import java.util.Scanner;

/*  a
    a b
    a b c
    a b c d
*/
public class pdf_7 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = 1; i <= lines; i++) {
      for (int j = 1; j <= i; j++) System.out.print((char) (96 + j) + " ");
      System.out.println();
    }
    sc.close();
  }
}
