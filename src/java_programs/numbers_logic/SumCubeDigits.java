package numbers_logic;
public class SumCubeDigits {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a no : ");
    int n = sc.nextInt(), s = 0;
    while (n != 0) {
      s += (int) Math.pow(n % 10, 3);
      n = n / 10;
    }
    System.out.println("Sum of the cube of digits = " + s);
    sc.close();
  }
}
