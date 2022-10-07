package numbers_logic;
/*
 *  A number is called a sunny number if the number next to the given number is a perfect square.
 *  In other words, a number N will be a sunny number if N+1 is a perfect square.
 */
public class SunnyNo {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a no. : ");
    int n = sc.nextInt();
    if (Math.sqrt(n + 1) - Math.floor(Math.sqrt(n + 1)) == 0) System.out.println("Sunny Number");
    else System.out.println("Not a Sunny Number");
    sc.close();
  }
}
