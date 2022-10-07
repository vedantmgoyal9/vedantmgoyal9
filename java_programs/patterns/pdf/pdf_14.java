package patterns.pdf;
/*  4 3 2 1
      3 2 1
        2 1
          1
*/
public class pdf_14 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter no. of lines to print : ");
    int lines = sc.nextInt();
    for (int i = lines; i >= 1; i--) {
      for (int j = lines; j > i; j--) System.out.print("  ");
      for (int j = i; j >= 1; j--) System.out.print(j + " ");
      System.out.println();
    }
    sc.close();
  }
}
