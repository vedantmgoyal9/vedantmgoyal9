package series_for_loop.pdf;
// A. 3^3 + 4^4 + 5^5 .....................N^N
public class a_SeriesX {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), s = 0;
    for (int i = 3; i <= (n + 2); i++) {
      s += Math.pow(i, i);
      if (i != 3) System.out.print(" + ");
      System.out.print(i + "^" + i);
    }
    System.out.print("\nSum : " + s);
    sc.close();
  }
}
