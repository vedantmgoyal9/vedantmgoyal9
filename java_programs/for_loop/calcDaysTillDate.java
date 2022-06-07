package java_programs.for_loop;

import java.util.Scanner;

public class calcDaysTillDate {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("Enter date (dd/mm/yyyy) : ");
    int d = sc.nextInt(), m = sc.nextInt(), y = sc.nextInt(), c = 0;
    for (int i = 1; i < m; i++)
      if (i == 4 || i == 6 || i == 9 || i == 11) c += 30;
      else if (i == 2 && (y % 400 == 0 || (y % 100 != 0 && y % 4 == 0))) c += 29;
      else if (i == 2) c += 28;
      else c += 31;
    c = c + d;
    System.out.println("No. of days till date : " + c);
    sc.close();
  }
}
