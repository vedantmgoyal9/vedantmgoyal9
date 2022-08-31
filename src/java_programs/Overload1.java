/*  ICSE 2016 Question 7
   Design a class to overload a function SumSeries() as follows: [15]
   (i) void SumSeries(int n, double x) – with one integer argument and one double argument
       to find and display the sum of the series given below:
       S = x/1 - x/2 + x/3 - x/4 + x/5 ... to n terms
  (ii) void SumSeries() – To find and display the sum of the following series:
       S = 1 + (1 x 2) + (1 x 2 x 3) + ….. + (1 x 2 x 3 x 4 x 20)
*/
public class Overload1 {
  private static void SumSeries(int n, double x) {
    double s = 0;
    for (int i = 1; i <= n; i++) {
      if (i % 2 == 0) s -= x / i;
      else s += x / i;
    }
    System.out.println("Sum of the Series: " + s);
  }

  private static void SumSeries() {
    long s = 1;
    for (int i = 2; i <= 20; i++) s += s * i;
    System.out.println("Sum of the series: " + s);
  }
  // main function for running program in ide different to BlueJ
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a choice: ");
    System.out.println("1: S = x/1 - x/2 + x/3 - x/4 + x/5 ... to n terms");
    System.out.println("2: S = 1 + (1 x 2) + (1 x 2 x 3) + ….. + (1 x 2 x 3 x 4 x 20)");
    System.out.println("Choice: ");
    char choice = sc.nextLine().charAt(0);
    if (choice == '1') {
      System.out.println("Enter n: ");
      int n = sc.nextInt();
      System.out.println("Enter x: ");
      int x = sc.nextInt();
      SumSeries(n, x);
    } else if (choice == '2') SumSeries();
    else System.out.println("Wrong Choice!");
    sc.close();
  }
}
