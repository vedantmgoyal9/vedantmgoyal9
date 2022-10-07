package numbers_logic;

public class SumOfAltDigitsWhileLoop {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a number : ");
    int n = sc.nextInt(), sumOdd = 0, sumEven = 0, c = 1;
    while (n != 0) {
      if (c % 2 == 0) sumEven += n % 10;
      else sumOdd += n % 10;
      n /= 10;
      c++;
    }
    System.out.println("Sum of digits at Even : " + sumEven);
    System.out.println("Sum of digits at Odd : " + sumOdd);
    sc.close();
  }
}
