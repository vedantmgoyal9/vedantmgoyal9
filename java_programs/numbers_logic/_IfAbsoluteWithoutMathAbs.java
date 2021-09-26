package numbers_logic;

class _IfAbsoluteWithoutMathAbs {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. : ");
    double n = sc.nextDouble();
    System.out.print("Absolute value of " + n + " = ");
    if (n < 0) n = -n;
    System.out.print(n);
    sc.close();
  }
}
