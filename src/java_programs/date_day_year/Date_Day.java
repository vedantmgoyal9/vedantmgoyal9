package java_programs.date_day_year;

import java.util.Scanner;

public class Date_Day {
  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);
    System.out.print("Enter current date (dd/mm/yyyy) : ");
    int d = sc.nextInt(), m = sc.nextInt(), y = sc.nextInt(), i, c = 0;
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
    switch (c) {
      case 0:
        System.out.print("Sunday");
        break;
      case 1:
        System.out.print("Monday");
        break;
      case 2:
        System.out.print("Tuesday");
        break;
      case 3:
        System.out.print("Wednesday");
        break;
      case 4:
        System.out.print("Thursday");
        break;
      case 5:
        System.out.print("Friday");
        break;
      case 6:
        System.out.print("Saturday");
        break;
      default:
        System.out.print("Invalid choice");
        break;
    }
    sc.close();
  }
}
