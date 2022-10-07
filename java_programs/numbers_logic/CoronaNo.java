package numbers_logic;
// a number whose all digits are odd.
public class CoronaNo {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a no. : ");
    int n = sc.nextInt();
    boolean areAllDigitsOdd = true;
    while (n != 0) {
      if ((n % 10) % 2 == 0) {
        areAllDigitsOdd = false;
        break;
      }
      n = n / 10;
    }
    if (areAllDigitsOdd) System.out.println("Corona Number");
    else System.out.println("Not a Corona Number");
    sc.close();
  }
}
