// 8545 2 Hours, 22 minutes and 25 seconds
class ConvertTime {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    int h, m, s;
    System.out.print("Enter seconds : ");
    s = sc.nextInt();
    h = s / 3600;
    s = s % 3600;
    m = s / 60;
    s = s % 60;
    System.out.print(h + " Hours, " + m + " Minutes & " + s + " Seconds");
    sc.close();
  }
}
