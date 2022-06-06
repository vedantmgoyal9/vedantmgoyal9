package java_programs.patterns.pdf;
/*  4 3 2 1
    3 2 1
    2 1
    1
*/
import java.util.Scanner;

public class pdf_9 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = lines; i >= 1; i--) {
      for (int j = i; j >= 1; j--) System.out.print(j + " ");
      System.out.println();
    }
    sc.close();
  }
}
