package java_programs.patterns.pdf;
/*  a b c d
      a b c
        a b
          a
*/
import java.util.Scanner;

public class pdf_16 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = lines; i >= 1; i--) {
      for (int j = lines; j > i; j--) System.out.print("  ");
      for (int j = 1; j <= i; j++) System.out.print((char) (96 + j) + " ");
      System.out.println();
    }
    sc.close();
  }
}
