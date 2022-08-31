package numbers_logic;
public class _Absolute_Ternary {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a no. : ");
    double n = sc.nextDouble();
    System.out.print("Absolute value of " + n + " = " + (n < 0 ? -n : n));
    sc.close();
  }
}
