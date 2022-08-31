package series_for_loop.pdf;
// S. 1,2,6,24,120................(10 TERM)
public class s_SeriesX {
  public static void main(String[] args) {
    for (int i = 1, c = 1; i <= 10; i++) {
      System.out.print(c *= (i + 1));
      if (i != 10) System.out.print(", ");
    }
  }
}
