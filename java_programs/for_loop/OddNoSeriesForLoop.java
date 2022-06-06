package java_programs.for_loop;
// Q.Write a program to display N terms of the following series, where N is input by the user.
// 1,3,5,7,9,11,...............
import java.util.*;

class OddNoSeriesForLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter no. of terms : ");
    int n = sc.nextInt(), i, a = 1;
    for (i = 1; i <= n; i++) {
      System.out.println(a);
      a += 2;
    }
    sc.close();
  }
}
