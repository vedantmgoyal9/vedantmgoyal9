package series_for_loop;
class SeriesSum_xpow1_xpow3_xpow5_xpow_n {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("This program calculates sum=x^1+x^3+x^5...x^n");
    System.out.print("Enter x : ");
    int x = sc.nextInt();
    System.out.print("Enter no. of terms : ");
    int term = sc.nextInt(), pow = 1, sum = 0;
    for (int i = 1; i <= term; i++) {
      sum += (int) Math.pow(x, pow);
      pow += 2;
    }
    System.out.println("sum=" + sum);
    sc.close();
  }
}
