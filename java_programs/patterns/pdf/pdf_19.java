package patterns.pdf;
/*    7
    7 5
  7 5 3
7 5 3 1
*/
public class pdf_19 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = lines; i >= 1; i--) {
      for (int j = i; j > 1; j--) System.out.print("  ");
      for (int j = lines; j >= i; j--) System.out.print((j * 2 - 1) + " ");
      System.out.println();
    }
    sc.close();
  }
}
