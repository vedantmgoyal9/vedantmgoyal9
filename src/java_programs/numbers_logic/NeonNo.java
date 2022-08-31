package numbers_logic;
// A positive integer whose sum of digits of its square is equal
// to the number itself is called a neon number.
// 9^2 = 81, 8 + 1 = 9, 9 is a neon number.
class NeonNo {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    int n, sq, s = 0;
    System.out.print("enter a number : ");
    n = sc.nextInt();
    for (sq = n * n; sq != 0; sq = sq / 10) s = s + sq % 10;
    if (s == n) System.out.print("Neon");
    else System.out.print("Not Neon");
    sc.close();
  }
}
