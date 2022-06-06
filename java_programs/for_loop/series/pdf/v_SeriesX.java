package java_programs.for_loop.series.pdf;
// V. 1/2 + 2/4 + 3/8 + 4/16.......................(10 TERMS)
public class v_SeriesX {
  public static void main(String[] args) {
    int denominator = 2;
    double s = 0;
    for (int i = 1; i <= 10; i++, denominator *= 2) {
      s += i / (double) denominator;
      if (i != 1) System.out.print(" + ");
      System.out.print(i + "/" + denominator);
    }
    System.out.print("\nSum : " + s);
  }
}
