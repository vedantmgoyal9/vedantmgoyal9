import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Scanner;

public class Calendar_Date_Ops {
  static private int d1, m1, y1, d2, m2, y2;

  private static boolean isDateValid(int date, int month, int year) {
    if (date <= 0 || month <= 0 || year <= 0 || date > 31 || month > 12)
      return false;
    if (month == 4 || month == 6 || month == 9 || month == 11)
      return date <= 30; // d == 31 is invalid
    if (month == 2 && isLeapYear(year))
      return date <= 29;
    return month == 2 ? date <= 28 : true;
  }

  private static boolean isLeapYear(int year) {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
  }

  private static int getDaysInMonth(int month, int year) {
    if (month == 4 || month == 6 || month == 9 || month == 11)
      return 30;
    if (month == 2 && isLeapYear(year))
      return 29;
    return month == 2 ? 28 : 31;
  }

  private static int getDaysTillDateInSameYear(int date, int month, int year) {
    if (!isDateValid(date, month, year))
      return -1;
    int noOfDays = 0;
    for (int i = 1; i < month; i++)
      noOfDays += getDaysInMonth(i, year);
    return noOfDays + date;
  }

  private static int calcDaysBetweenDates(int d1, int m1, int y1, int d2, int m2, int y2) {
    if (!isDateValid(d1, m1, y1) || !isDateValid(d2, m2, y2))
      return -1;
    if (y1 == y2)
      return getDaysTillDateInSameYear(d2, m2, y2) - getDaysTillDateInSameYear(d1, m1, y1);
    int noOfDays = getDaysTillDateInSameYear(d2, m2, y2)
        + (isLeapYear(y1) ? 366 : 365)
        - getDaysTillDateInSameYear(d1, m1, y1);
    for (int i = y1 + 1; i < y2; i++)
      noOfDays += isLeapYear(i) ? 366 : 365;
    return noOfDays;
    // Calendar c1 = Calendar.getInstance();
    // c1.get(Calendar.DAY_OF_WEEK);
    // Calendar c2 = Calendar.getInstance();
    // c2.set(y2, m2 - 1, d2);
    // long diff = c2.getTimeInMillis() - c1.getTimeInMillis();
    // return (int) (diff / (24 * 60 * 60 * 1000));
  }

  private static String getDayOnDate(int date, int month, int year) {
    switch (calcDaysBetweenDates(1, 1, 1, date, month, year) % 7) {
      case 0:
        return "Monday";
      case 1:
        return "Tuesday";
      case 2:
        return "Wednesday";
      case 3:
        return "Thursday";
      case 4:
        return "Friday";
      case 5:
        return "Saturday";
      case 6:
        return "Sunday";
      default:
        return "Error while calculating day";
    }
  }

  private static String getDateInWords(int date, int month, int year) {
    if (!isDateValid(date, month, year))
      return "Invalid Date";
    Calendar calendar = Calendar.getInstance();
    calendar.set(year, month - 1, date); // year, month, date
    return new SimpleDateFormat("dd MMMM yyyy").format(calendar.getTime());
  }

  public static void main(String[] args) {
    Scanner sc = new Scanner(System.in);

    System.out.println("Enter date 1:");
    d1 = sc.nextInt();
    System.out.println("Enter month 1:");
    m1 = sc.nextInt();
    System.out.println("Enter year 1:");
    y1 = sc.nextInt();
    System.out.println("Enter date 2:");
    d2 = sc.nextInt();
    System.out.println("Enter month 2:");
    m2 = sc.nextInt();
    System.out.println("Enter year 2:");
    y2 = sc.nextInt();

    System.out.println("Date1 in words: " + getDateInWords(d1, m1, y1));
    System.out.println("Day on Date1: " + getDayOnDate(d1, m1, y1));
    System.out.println("Is Date1 valid: " + isDateValid(d1, m1, y1));
    System.out.println("Date2 in words: " + getDateInWords(d2, m2, y2));
    System.out.println("Day on Date2: " + getDayOnDate(d2, m2, y2));
    System.out.println("Is Date2 valid: " + isDateValid(d2, m2, y2));
    System.out.println("Days from start of year till Date1: " + getDaysTillDateInSameYear(d1, m1, y1));
    System.out.println("Days from start of year till Date2: " + getDaysTillDateInSameYear(d2, m2, y2));
    System.out.println("Days between dates: " + calcDaysBetweenDates(d1, m1, y1, d2, m2, y2));
  }
}
