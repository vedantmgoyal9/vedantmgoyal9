package series_for_loop;
// 1,2,4,7,11,16..........
class Series_1_2_4_7 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), a = 1;
    for (int i = 0; i < n; i++) {
      System.out.print(a += i);
      if (i != n - 1) System.out.print(", ");
    }
    sc.close();
  }
}
