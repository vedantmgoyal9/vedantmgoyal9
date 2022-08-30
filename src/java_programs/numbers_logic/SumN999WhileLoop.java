package java_programs.numbers_logic;

import java.util.Scanner;

public class SumN999WhileLoop {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter some numbers : ");
    int n, sum = 0;
    while (true) {
      n = sc.nextInt();
      if (n == -999) {
        System.out.println("Sum of no. entered till now : " + sum);
        break;
      } else sum += n;
    }
    sc.close();
  }
}
