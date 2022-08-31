package series_for_loop.pdf;
// E. 1, 12, 123, 1234, 12345............ N TERMS.
class e_SeriesX {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), i, a = 0;
    for (i = 1; i <= n; i++) {
      a = a * 10 + i;
      System.out.println(a);
    }
    sc.close();
  }
}
