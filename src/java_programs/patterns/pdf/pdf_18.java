package patterns.pdf;
/*      1
      2 1
    3 2 1
  4 3 2 1
*/
public class pdf_18 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = 1; i <= lines; i++) {
      for (int j = i; j < lines; j++) System.out.print("  ");
      for (int j = i; j >= 1; j--) System.out.print(j + " ");
      System.out.println();
    }
    sc.close();
  }
}
