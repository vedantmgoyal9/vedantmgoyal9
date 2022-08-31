package series_for_loop.pdf;
// I. S= 1-2+3-4 ............................N TERMS.
class i_SeriesX {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), i, s = 0;
    for (i = 1; i <= n; i++)
      if (i % 2 == 0) {
        s = s - i;
        System.out.print(-i);
      } else {
        s = s + i;
        if (i != 1) System.out.print("+");
        System.out.print(i);
      }
    System.out.print("\nSum=" + s);
    sc.close();
  }
}
