package java_programs.patterns.pdf;

import java.util.Scanner;

/*  4
    3 4
    2 3 4
    1 2 3 4
*/
public class pdf_2 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = lines; i >= 1; i--) {
      for (int j = i; j <= lines; j++) System.out.print(j + " ");
      System.out.println();
    }
    sc.close();
  }
}
