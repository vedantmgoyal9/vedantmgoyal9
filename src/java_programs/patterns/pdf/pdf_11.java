package patterns.pdf;
/*  1 2 3 4
    2 4 6
    3 6
    4
*/
public class pdf_11 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt(), c = 1;
    for (int i = lines; i >= 1; i--, c++) {
      for (int j = 1; j <= i; j++) System.out.print(j * c + " ");
      System.out.println();
    }
    sc.close();
  }
}
