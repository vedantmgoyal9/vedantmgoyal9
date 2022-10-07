public class Pyramid1 {
  public static void main(String[] args) {
    int rows = 5;
    for (int i = 1; i <= rows; ++i) {
      for (int j = 1; j <= i; ++j) {
        System.out.print("1");
      }
      System.out.println();
    }
  }
}
