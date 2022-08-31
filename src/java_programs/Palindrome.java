public class Palindrome {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a number : ");
    int n = sc.nextInt();
    if (n / 100 == n % 10 % 10) System.out.print(n + " is a palindrome number.");
    else System.out.print(n + " is not a palindrome number.");
    sc.close();
  }
}
