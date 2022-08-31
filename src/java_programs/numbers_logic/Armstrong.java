package numbers_logic;
class Armstrong {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a no : ");
    int n = sc.nextInt(), s = 0, t = n;
    while (n != 0) {
      s = s + (n % 10) * (n % 10) * (n % 10);
      n = n / 10;
    }
    if (s == t) System.out.print("Armstrong number");
    else System.out.print("Not Armstrong number");
    sc.close();
  }
}
