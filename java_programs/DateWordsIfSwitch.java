class DateWordsIfSwitch {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter date, month and year : ");
    int d = sc.nextInt(), m = sc.nextInt(), y = sc.nextInt();
    System.out.print(d);
    if (d == 1 || d == 21 || d == 31) System.out.print("st ");
    else if (d == 2 || d == 22) System.out.print("nd ");
    else if (d == 3 || d == 23) System.out.print("rd ");
    else System.out.print("th ");
    switch (m) {
      case 1:
        System.out.print("January ");
        break;
      case 2:
        System.out.print("February ");
        break;
      case 3:
        System.out.print("March ");
        break;
      case 4:
        System.out.print("April ");
        break;
      case 5:
        System.out.print("May ");
        break;
      case 6:
        System.out.print("June ");
        break;
      case 7:
        System.out.print("July ");
        break;
      case 8:
        System.out.print("August ");
        break;
      case 9:
        System.out.print("September ");
        break;
      case 10:
        System.out.print("October ");
        break;
      case 11:
        System.out.print("November ");
        break;
      default:
        System.out.print("December ");
        break;
    }
    System.out.print(y);
    sc.close();
  }
}
