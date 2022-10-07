package matrix_dd_array;

public class identity_matrix {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter the size of the matrix: ");
    int n = sc.nextInt();
    int[][] a = new int[n][n];
    for (int i = 0; i < n; i++)
      for (int j = 0; j < n; j++) {
        System.out.println("Enter the element for row " + i + " and column " + j + ": ");
        a[i][j] = sc.nextInt();
      }
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) System.out.print(a[i][j] + "\t");
      System.out.println();
    }
    for (int i = 0; i < n; i++)
      for (int j = 0; j < n; j++)
        if ((i == j && a[i][j] != 1) || (i != j && a[i][j] != 0)) {
          System.out.println("The matrix is not an identity matrix.");
          System.exit(0);
        }
    System.out.println("The matrix is an identity matrix.");
    sc.close();
  }
}
