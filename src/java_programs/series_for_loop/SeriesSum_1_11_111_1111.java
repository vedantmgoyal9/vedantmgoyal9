package series_for_loop;
public class SeriesSum_1_11_111_1111 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), j = 1, s = 0;
    for (int i = 1; i <= n; i++) {
      s += j;
      j = j * 10 + 1;
    }
    System.out.println("Sum = " + s);
    sc.close();
  }
}
