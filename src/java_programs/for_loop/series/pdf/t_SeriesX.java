package java_programs.for_loop.series.pdf;
// T. 1,3,9,27,81...................(10 TERM)
public class t_SeriesX {
  public static void main(String[] args) {
    for (int i = 1, c = 1; i <= 10; i++, c *= 3) {
      System.out.print(c);
      if (i != 10) System.out.print(", ");
    }
  }
}
