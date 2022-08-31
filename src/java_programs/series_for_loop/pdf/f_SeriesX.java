package series_for_loop.pdf;
// F. 1, 4, 9, 16, 25............ N TERMS.
public class f_SeriesX {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter no. of terms : ");
    int n = sc.nextInt(), add = 1;
    for (int i = 0; i < n; i++) {
      for (int c = 1; c <= i; c++) add += 2;
      System.out.print(add + i);
      if (i != n - 1) System.out.print(", ");
    }
    sc.close();
  }
}
