package numbers_logic;
// A number in which the sum of factorials of each digit is equal to the sum of the number itself
public class PetersonNo {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a number : ");
    int n = sc.nextInt(), sum = 0, t = n, f = 1;
    while (t > 0) {
      for (int i = 1; i <= t % 10; i++) f = f * i;
      sum += f;
      f = 1;
      t = t / 10;
    }
    if (sum == n) System.out.println("Peterson Number");
    else System.out.println("Not a Peterson Number");
    sc.close();
  }
}
