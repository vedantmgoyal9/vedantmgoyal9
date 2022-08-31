package numbers_logic;
class PalindromeNo {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a no : ");
    int n = sc.nextInt(), t = n, r = 0;
    while (t != 0) {
      r = r * 10 + t % 10;
      t = t / 10;
    }
    if (r == t) System.out.print("Palindrome number");
    else System.out.print("Not Palindrome number");
    sc.close();
  }
}
