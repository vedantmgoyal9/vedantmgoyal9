package numbers_logic;
public class KaprekarNo {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a no. : ");
    int n = sc.nextInt(), t = n, a = 1;
    while (t != 0) {
      a = a * 10;
      t = t / 10;
    }
    t = n * n;
    if ((t % a) + (t / a) == n) System.out.print("The number " + n + " is a Kaprekar No. ");
    else System.out.print("The number " + n + " is not a Kaprekar No. ");
    sc.close();
  }
}
