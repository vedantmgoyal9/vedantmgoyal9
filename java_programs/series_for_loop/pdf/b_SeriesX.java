package series_for_loop.pdf;
// B. 1/3 + 2/5 + 3/9 + 4/15............(10 TERMS)
public class b_SeriesX {
  public static void main(String[] args) {
    int add = 0, denominator = 3;
    double sum = 0;
    for (int i = 1; i <= 10; i++, denominator += add += 2) {
      sum += i / (double) denominator;
      if (i != 1) System.out.print(" + ");
      System.out.print(i + "/" + denominator);
    }
    System.out.print("\nSum : " + sum);
  }
}
