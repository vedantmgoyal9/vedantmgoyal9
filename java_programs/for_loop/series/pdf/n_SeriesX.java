package java_programs.for_loop.series.pdf;
// N. S = 1 + 2+ 3 + 4+ ....................................+N TERMS.
import java.util.Scanner;

public class n_SeriesX {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
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
