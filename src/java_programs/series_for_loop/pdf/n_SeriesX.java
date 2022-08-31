package series_for_loop.pdf;
// N. S = 1 + 2+ 3 + 4+ ....................................+N TERMS.
public class n_SeriesX {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), sum = 0;
    for (int i = 1; i <= n; i++) {
      sum += i;
      if (i != 1) System.out.print(" + ");
      System.out.print(i);
    }
    System.out.println("\nSum : " + sum);
    sc.close();
  }
}
