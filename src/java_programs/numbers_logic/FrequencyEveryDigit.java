package java_programs.numbers_logic;

import java.util.*;

class FrequencyEveryDigit {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter a no : ");
    long n = sc.nextLong(), t = n;
    int c = 0;
    System.out.println("Digit\tFrequency");
    for (int i = 0; i <= 9; i++, t = n, c = 0) {
      while (t > 0) {
        if (t % 10 == i) c++;
        t = t / 10;
      }
      if (c >= 1) System.out.println(i + "\t\t" + c);
    }
    sc.close();
  }
}
