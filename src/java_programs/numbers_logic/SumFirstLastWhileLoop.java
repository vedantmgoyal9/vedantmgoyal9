package numbers_logic;

class SumFirstLastWhileLoop {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a no : ");
    int n = sc.nextInt(), c = 0, fd = n, ld = n % 10;
    while (n != 0) {
      c++;
      n = n / 10;
    }
    if (c == 1) System.out.println("Sum of first and last digits = " + (fd));
    else {
      while (fd > 9) fd /= 10;
      System.out.println("Sum of first and last digits = " + (fd + ld));
    }
    sc.close();
  }
}
