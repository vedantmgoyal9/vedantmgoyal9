package patterns.combined;
public class c {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a no. : ");
    int n = sc.nextInt();
    int i, j, s = n + 1, e = n - 1;
    for (i = 1; i <= n; i++) {
      for (j = 1; j < 2 * n; j++)
        if (j >= s && j <= e) System.out.print("  ");
        else System.out.print(j + " ");
      s--;
      e++;
      System.out.println();
    }
  }
}
