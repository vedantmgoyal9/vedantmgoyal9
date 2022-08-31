package numbers_logic;

public class Palindrome_SuperP_DuperP {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a number: ");
    int n = sc.nextInt();
    enterChoice(n);
    sc.close();
  }

  private static void enterChoice(int n) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a choice:");
    System.out.println("A: Check number for Palindrome");
    System.out.println("B: Check number for Super Palindrome");
    System.out.println("C: Check number for Super Duper Palindrome");
    char choice = sc.next().charAt(0);
    switch (choice) {
      case 'a':
      case 'A':
        if (checkPalindrome(n)) System.out.println("Palindrome");
        else System.out.println("Not Palindrome");
        break;
      case 'b':
      case 'B':
        if (checkPalindrome(n) && checkPalindrome(n * n)) System.out.println("Super Palindrome");
        else System.out.println("Not Super Palindrome");
        break;
      case 'c':
      case 'C':
        if (checkPalindrome(n) && checkPalindrome(n * n) && checkPalindrome(n * n * n * n))
          System.out.println("Super Duper Palindrome");
        else System.out.println("Not Super Duper Palindrome");
        break;
      default:
        System.out.println("Wrong Choice");
        enterChoice(n);
        break;
    }
    sc.close();
  }

  private static boolean checkPalindrome(int n) {
    int x = 0, t = n;
    while (t != 0) {
      x = x * 10 + t % 10;
      t /= 10;
    }
    return x == n;
  }
}
