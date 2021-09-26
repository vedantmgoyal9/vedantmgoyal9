package series_for_loop;

public class Series_1_22_333 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), a = 0;
    for (int i = 1; i <= n; i++) {
      a = a * 10 + 1;
      System.out.println(a * i);
    }
    sc.close();
  }
}
