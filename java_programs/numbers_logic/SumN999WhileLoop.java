package numbers_logic;

public class SumN999WhileLoop {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter some numbers : ");
    int n, sum = 0;
    while (true) {
      n = sc.nextInt();
      if (n == -999) {
        System.out.println("Sum of no. entered till now : " + sum);
        break;
      } else sum += n;
    }
    sc.close();
  }
}
