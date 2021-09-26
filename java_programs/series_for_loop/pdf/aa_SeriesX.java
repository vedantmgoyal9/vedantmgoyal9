package series_for_loop.pdf;
// AA. 1/1! – 1/2! + 1/3! – 1/4! + 1/5! ............N.
public class aa_SeriesX {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt();
    double s = 0, f = 1;
    for (int i = 1; i <= n; i++, f = 1) {
      for (int findFactorial = 1; findFactorial <= i; findFactorial++) f *= findFactorial;
      if (i % 2 == 0) {
        s -= 1 / f;
        System.out.print(-1 + "/" + f);
      } else {
        s += 1 / f;
        if (i != 1) System.out.print("+");
        System.out.print(1 + "/" + f);
      }
    }
    System.out.print("\nSum : " + s);
    sc.close();
  }
}
