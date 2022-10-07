package series_for_loop.pdf;
// H. 1!, 2!, 3!..................... N TERMS.
public class h_SeriesX {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt();
    for (int i = 1; i <= n; i++) {
      int f = 1;
      for (int findFactorial = 1; findFactorial <= i; findFactorial++) f *= findFactorial;
      System.out.print(f);
      if (i != n) System.out.print(", ");
    }
    sc.close();
  }
}
