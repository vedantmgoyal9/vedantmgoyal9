package series_for_loop.pdf;
// W. 1+X+(X^1)/1! + (X^2)/2! + (X^3)/3! + (X^4)/4!...................(X^N)/N!
public class w_SeriesX {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter X and no. of terms : ");
    int x = sc.nextInt(), n = sc.nextInt(), term = 1;
    double f = 1, s = 1 + x;
    System.out.print("1 + " + x);
    for (int i = 3; i <= n; i++, term++) {
      f *= (i - 2);
      s += (Math.pow(x, term) / f);
      System.out.print(" + " + Math.pow(x, term) + "/" + f);
    }
    System.out.print("\nSum : " + s);
    sc.close();
  }
}
