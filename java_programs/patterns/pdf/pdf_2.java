package patterns.pdf;
/*  4
    3 4
    2 3 4
    1 2 3 4
*/
public class pdf_2 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = lines; i >= 1; i--) {
      for (int j = i; j <= lines; j++) System.out.print(j + " ");
      System.out.println();
    }
    sc.close();
  }
}
