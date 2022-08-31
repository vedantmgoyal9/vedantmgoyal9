package patterns;
public class TriangleMouldStar_V {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a no. : ");
    int n = sc.nextInt(), s = n * 2 - 3;
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= i; j++) System.out.print("*");
      for (int j = 1; j <= s; j++) System.out.print(" ");
      s -= 2;
      for (int j = i == n ? n - 1 : i; j >= 1; j--) System.out.print("*");
      System.out.println();
    }
    sc.close();
  }
}
