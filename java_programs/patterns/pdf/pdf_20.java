package java_programs.patterns.pdf;

import java.util.Scanner;

/*       a
       a c
     a c e
   a c e g
*/
public class pdf_20 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = 1; i <= lines; i++) {
      for (int j = lines; j > i; j--) System.out.print("  ");
      for (int j = 1; j <= i; j++) System.out.print((char) (96 + j * 2 - 1) + " ");
      System.out.println();
    }
    sc.close();
  }
}
