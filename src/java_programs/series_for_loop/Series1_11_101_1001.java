package java_programs.series_for_loop;

// 1,11,101,1001,10001.............
import java.util.*;

class Series1_11_101_1001 {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Input number of terms : ");
    int n = sc.nextInt();
    long a = 1, s = 1;
    for (int i = 1; i < n; i++) {
      System.out.println(a);
      if (a == 1) a = a * 10 + 1;
      else a = (a * 10) - 9;
      s = s + a;
    }
    System.out.println(a);
    System.out.println("Sum = " + s);
    sc.close();
  }
}
