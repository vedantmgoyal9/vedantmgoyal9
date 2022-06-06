package java_programs.patterns.pdf;
/*  d c b a
    c b a
    b a
    a
*/
import java.util.Scanner;

public class pdf_10 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = lines; i >= 1; i--) {
      for (int j = i; j >= 1; j--) System.out.print((char) (96 + j) + " ");
      System.out.println();
    }
    sc.close();
  }
}
