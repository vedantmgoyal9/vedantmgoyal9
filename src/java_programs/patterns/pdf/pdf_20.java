package patterns.pdf;
/*       a
       a c
     a c e
   a c e g
*/
public class pdf_20 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
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
