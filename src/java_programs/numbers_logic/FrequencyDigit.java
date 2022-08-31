package numbers_logic;

class FrequencyDigit {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a no : ");
    int n = sc.nextInt();
    System.out.print("Enter a digit : ");
    int d = sc.nextInt(), c = 0;
    while (n > 0) {
      if (n % 10 == d) c++;
      n = n / 10;
    }
    System.out.println("Number of " + d + "s in digit : " + c);
    sc.close();
  }
}
