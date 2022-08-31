package date_day_year;
public class calcDaysBirthTillDate {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter your birthday (dd/mm/yyyy): ");
    int bd = sc.nextInt(), bm = sc.nextInt(), by = sc.nextInt();
    System.out.print("Enter current date (dd/mm/yyyy) : ");
    int d = sc.nextInt(), m = sc.nextInt(), y = sc.nextInt(), i, c = 0;
    for (i = 1; i < bm; i++)
      if (i == 4 || i == 6 || i == 9 || i == 11) c = c + 30;
      else if (i == 2 && (by % 400 == 0 || (by % 100 != 0 && by % 4 == 0))) c = c + 29;
      else if (i == 2) c = c + 28;
      else c = c + 31;
    c = c + bd;
    if (by % 400 == 0 || (by % 100 != 0 && by % 4 == 0)) c = 366 - c;
    else c = 365 - c;
    for (i = by + 1; i < y; i++)
      if (i % 400 == 0 || (i % 100 != 0 && i % 4 == 0)) c = c + 366;
      else c = c + 365;
    for (i = 1; i < m; i++)
      if (i == 4 || i == 6 || i == 9 || i == 11) c = c + 30;
      else if (i == 2 && (y % 400 == 0 || (y % 100 != 0 && y % 4 == 0))) c = c + 29;
      else if (i == 2) c = c + 28;
      else c = c + 31;
    c = c + d;
    System.out.print("No. of days : " + c);
    sc.close();
  }
}
