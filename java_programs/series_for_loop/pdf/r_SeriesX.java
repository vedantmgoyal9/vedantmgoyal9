package series_for_loop.pdf;
// R. 1,2,4,8,16..............10 TERMS
public class r_SeriesX {
  public static void main(String[] args) {
    for (int i = 1, x = 1; i <= 10; i++, x *= 2) {
      System.out.print(x);
      if (i != 10) System.out.print(", ");
    }
  }
}
