public class roman_decimal {
  private static final char[] roman = {'I', 'V', 'X', 'L', 'C'};
  private static final int[] decimal = {1, 5, 10, 50, 100};
  private static String res = null;

  private static String convertToRoman(int n) {
    int i = 0;
    while (n > 0) {
      int r = n % 10;
      if (r <= 3) {
        for (int j = 0; j < r; j++) res = roman[i] + res;
      } else if (r == 4) res = roman[i] + "" + roman[i + 1] + res;
      else if (r == 5) res = roman[i + 1] + res;
      else if (r <= 8) {
        for (int j = 0; j < r - 5; j++) {
          res = roman[i] + res;
        }
        res = roman[i + 1] + res;
      } else if (r == 9) res = roman[i] + "" + roman[i + 2] + res;

      n = n / 10;
      i = i + 2;
    }
    return res;
  }

  private static String convertToDecimal(String s) {
    // convert roman string to decimal number
    int n = 0;
    for (int i = 0; i < s.length(); i++) {
      char c = s.charAt(i);
      int d = 0;
      for (int j = 0; j < roman.length; j++) {
        if (c == roman[j]) {
          d = decimal[j];
          break;
        }
      }
      if (i + 1 < s.length()) {
        char c1 = s.charAt(i + 1);
        int d1 = 0;
        for (int j = 0; j < roman.length; j++) {
          if (c1 == roman[j]) {
            d1 = decimal[j];
            break;
          }
        }
        if (d < d1) {
          n = n + d1 - d;
          i++;
        } else n = n + d;
      } else n = n + d;
    }
    return n + "";
  }

  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a number b/w 1 to 100 in any format: ");
    String s = sc.next();

    // try parsing the input to integer
    // if it fails then it is a roman number string
    try {
      int n = Integer.parseInt(s);
      System.out.println("Roman number: " + convertToRoman(n));
    } catch (NumberFormatException e) {
      System.out.println("Decimal number: " + convertToDecimal(s));
    }
    sc.close();
  }
}
