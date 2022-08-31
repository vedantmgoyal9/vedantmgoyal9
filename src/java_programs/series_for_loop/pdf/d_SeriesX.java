package series_for_loop.pdf;
// d. 1 , 11,111,1111,11111......... N TERMS.
public class d_SeriesX {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), a = 0;
    for (int i = 1; i <= n; i++) {
      a = a * 10 + 1;
      System.out.println(a);
    }
    sc.close();
  }
}
