package java_programs.while_loop;

import java.io.IOException;
import java.util.Scanner;

class DisariumNoWhileLoop {
  public static void main(String[] args) throws IOException {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no : ");
    int n = sc.nextInt(), count = 0, t = n, sum = 0;
    while (t != 0) {
      count++;
      t /= 10;
    }
    t = n;
    while (t != 0) {
      sum = (int) (sum + Math.pow((t % 10), count--));
      t /= 10;
    }
    if (sum == n) System.out.println("Disarium Number");
    else System.out.println("Not a Disarium Number");
    sc.close();
  }
}
