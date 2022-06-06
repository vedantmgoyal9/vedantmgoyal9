package java_programs.for_loop.series.pdf;
// DD. S = 1 X 2 + 2 X 3 + 3 X 4 +...... + 19 X 20
public class dd_SeriesX {
  public static void main(String[] args) {
    int sum = 0;
    for (int i = 1; i < 20; i++) {
      sum += i * (i + 1);
      if (i != 1) System.out.print(" + ");
      System.out.print(i + "x" + (i + 1));
    }
    System.out.println("\nSum : " + sum);
  }
}
