package java_programs.while_loop;

import java.util.Scanner;
// A number in which the sum of factorials of each digit is equal to the sum of the number itself

public class peterson_number {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
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
