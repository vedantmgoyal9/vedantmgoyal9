package java_programs.patterns.pdf;
/*  1 2 3 4
    1 2 3
    1 2
    1
*/
import java.util.Scanner;

public class pdf_8 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = lines; i >= 1; i--) {
      for (int j = 1; j <= i; j++) System.out.print(j + " ");
      System.out.println();
    }
    sc.close();
  }
}
