package patterns.diamond;

public class BarfiNo {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a no. : ");
    int n = sc.nextInt();
    int i, j;
    for (i = 1; i <= n; i++) {
      for (j = n; j > i; j--) System.out.print("   ");
      for (j = 1; j <= i; j++)
        if (j <= 9) System.out.print(j + "  ");
        else System.out.print(j + " ");
      for (j = i - 1; j >= 1; j--)
        if (j <= 9) System.out.print(j + "  ");
        else System.out.print(j + " ");
      System.out.println();
    }
    for (i = n - 1; i >= 1; i--) {
      for (j = n - 1; j >= i; j--) System.out.print("   ");
      for (j = 1; j <= i; j++)
        if (j <= 9) System.out.print(j + "  ");
        else System.out.print(j + " ");
      for (j = i - 1; j >= 1; j--)
        if (j <= 9) System.out.print(j + "  ");
        else System.out.print(j + " ");
      System.out.println();
    }
  }
}
