package conditions_ninth;
/*      Income         Tax
 * 250000              Nil.
 * 250001 to 500000    10%
 * 500001 to 1000000   20%
 * 1000001 and above   30%
 */
class IncomeTax {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter Annual Income : ");
    double inc = sc.nextDouble(), tax = 0;
    if (inc <= 250000) tax = 0;
    else if (inc > 250000 && inc <= 500000) tax = (inc - 250000) * 0.1;
    else if (inc > 500000 && inc <= 1000000) tax = 25000 + (inc - 500000) * 0.2;
    else tax = 25000 + 100000 + (inc - 1000000) * 0.3;
    System.out.println("Annual Income = " + inc);
    System.out.println("Income Tax  = " + tax);
    sc.close();
  }
}
