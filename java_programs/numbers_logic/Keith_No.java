package numbers_logic;

public class Keith_No {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a no. : ");
    int n = sc.nextInt(), sum = 0, temp = n, lastTerm = n % 10;
    while (temp > 0) {
      sum += lastTerm;
      lastTerm = temp % 10;
      temp /= 10;
    }
    while (true) {
      if (sum == n) {
        System.out.println(n + " is a Keith no.");
        break;
      } else if (sum > n) {
        System.out.println(n + " is not a Keith no.");
        break;
      }
      // lastTerm =
    }
    sc.close();
  }
}
