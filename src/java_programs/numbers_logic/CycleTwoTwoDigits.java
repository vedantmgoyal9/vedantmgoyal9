package numbers_logic;
public class CycleTwoTwoDigits {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a number : ");
    int n = sc.nextInt(), r = 0, c = 0, i;
    for (i = n; i != 0; i = i / 10) c++;
    for (i = n, n = 0; i != 0; i = i / 10) n = n * 10 + i % 10;
    for (i = 1; i <= (c % 2 == 0 ? c / 2 : c / 2 + 1); i++, n /= 100) {
      if (n % 100 / 10 != 0) r = r * 100 + n % 100 / 10 * 10 + n % 10;
      else r = r * 10 + n % 10;
    }
    System.out.println("After cycling 2-2 digits, no. is: " + r);
    sc.close();
  }
}
