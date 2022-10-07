package patterns.pdf;
/*  1 2 3 4
    1 2 3
    1 2
    1
*/
public class pdf_8 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = lines; i >= 1; i--) {
      for (int j = 1; j <= i; j++) System.out.print(j + " ");
      System.out.println();
    }
    sc.close();
  }
}
