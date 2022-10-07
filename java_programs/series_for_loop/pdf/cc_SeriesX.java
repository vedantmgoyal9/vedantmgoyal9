package series_for_loop.pdf;
// CC. 1+2/1*2,1+2+3/1*2*3,1+2+3+4/1*2*3*4,1+2+3+4+.......N/1*2*3*4*......N
public class cc_SeriesX {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), pr = 1, sum = 0;
    for (int i = 1; i <= n + 1; i++) {
      sum += i;
      pr *= i;
      if (sum != 1) System.out.print(sum + "/" + pr);
      if (i != 1 && i != n + 1) System.out.print(", ");
    }
    sc.close();
  }
}
