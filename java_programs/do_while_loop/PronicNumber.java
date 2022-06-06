package java_programs.do_while_loop;
// ICSE 2018
import java.util.Scanner;

public class PronicNumber {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter a number: ");
    int n = sc.nextInt(), i = 1;
    boolean isPronic = false;
    do {
      if (i * (i + 1) == n) {
        isPronic = true;
        break;
      }
      i++;
    } while (i * (i + 1) <= n);
    System.out.println(isPronic ? "Pronic Number" : "Not a Pronic Number");
  }
}
