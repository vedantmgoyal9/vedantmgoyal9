public class matrix_animate_boundaries {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter rows of array: ");
    int rows = sc.nextInt();
    System.out.println("Enter columns of array: ");
    int cols = sc.nextInt();
    int arr[][] = new int[rows][cols];
    for (int i = 0; i < rows; i++) for (int j = 0; j < cols; j++) arr[i][j] = sc.nextInt();
    sc.close();
    while (true) {
      try {
        Thread.sleep(1000); // time delay
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
      System.out.print("\033[H\033[2J"); // clear screen
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++)
          if (i == 0 || i == rows - 1 || j == 0 || j == cols - 1)
            System.out.print(arr[i][j] + "\t");
          else System.out.print("\t");
        System.out.println();
      }
      // shift boundary elements
      int temp = arr[0][0];
      for (int i = 0; i < cols - 1; i++) arr[0][i] = arr[0][i + 1];
      for (int i = 0; i < rows - 1; i++) arr[i][cols - 1] = arr[i + 1][cols - 1];
      for (int i = cols - 1; i > 0; i--) arr[rows - 1][i] = arr[rows - 1][i - 1];
      for (int i = rows - 1; i > 0; i--) arr[i][0] = arr[i - 1][0];
      arr[1][0] = temp;
    }
  }
}
