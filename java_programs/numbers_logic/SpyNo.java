package numbers_logic;

class SpyNo {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    int i, n, s = 0, p = 1;
    System.out.print("enter a number : ");
    n = sc.nextInt();
    for (i = n; i != 0; i = i / 10) {
      s = s + i % 10;
      p = p * (i % 10);
    }
    if (s == p) System.out.print("Spy");
    else System.out.print("Not Spy");
    sc.close();
  }
}
