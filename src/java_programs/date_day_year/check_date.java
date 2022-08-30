package java_programs.date_day_year;

import java.util.*;

public class check_date {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.println("enter a date,month,year : ");
    int d = sc.nextInt();
    int m = sc.nextInt();
    int y = sc.nextInt();
    if (d <= 0 || m <= 0 || y <= 0 || d > 31 || m > 12) {
      System.out.print("Invalid Date");
      System.exit(0);
    } else if ((m == 4 || m == 6 || m == 9 || m == 11) && d == 31) {
      System.out.print("Invalid Date");
      System.exit(0);
    } else if (m == 2 && (y % 400 == 0 || (y % 100 != 0 && y % 4 == 0)) && d > 29) {
      System.out.print("Invalid Date");
      System.exit(0);
    } else if (m == 2 && d > 28) {
      System.out.print("Invalid Date");
      System.exit(0);
    }
    int c = 0, i;
    for (i = 1; i < y; i++)
      if (i % 400 == 0 || (i % 100 != 0 && i % 4 == 0)) c = c + 366;
      else c = c + 365;
    for (i = 1; i < m; i++)
      if (i == 4 || i == 6 || i == 9 || i == 11) c = c + 30;
      else if (i == 2 && (y % 400 == 0 || (y % 100 != 0 && y % 4 == 0))) c = c + 29;
      else if (i == 2) c = c + 28;
      else c = c + 31;
    c = c + d;
    c = c % 7;
    if (c == 0) System.out.print("Sunday");
    else if (c == 1) System.out.print("Monday");
    else if (c == 2) System.out.print("Tuesday");
    else if (c == 3) System.out.print("Wednesday");
    else if (c == 4) System.out.print("Thursday");
    else if (c == 5) System.out.print("Friday");
    else System.out.print("Saturday");
    sc.close();
  }
}
