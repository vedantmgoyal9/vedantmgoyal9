package numbers_logic;

class MagicNo {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a number : ");
    int n = sc.nextInt();
    while (n > 9) {
      int s = 0;
      while (n > 0) {
        s = s + n % 10;
        n = n / 10;
      }
      n = s;
    }
    if (n == 1) System.out.print("Magic number");
    else System.out.print("Not a magic number");
    sc.close();
  }
}
