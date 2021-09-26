import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Scanner;

public class Number_Ops {
    private final Scanner sc = new Scanner(System.in);
    private int a, b; // not static

    Number_Ops() {
        a = b = 0;
    }

    private boolean isBuzz(int n) {
        return n % 10 == 7 || n % 7 == 0;
    }

    private boolean isSpy(int n) {
        int sum = 0, product = 1;
        for (int digit : getDigits(n)) {
            sum += digit;
            product *= digit;
        }
        return sum == product;
    }

    private boolean isNeon(int n) {
        /*
         * A positive integer whose sum of digits of its square is equal to the number
         * itself is called a neon number. 9^2 = 81, 8 + 1 = 9, 9 is a neon number.
         */
        int sum = 0;
        for (int square = n * n; square != 0; square /= 10)
            sum += square % 10;
        return sum == n;
    }

    private static boolean isTech(int n) {
        /*
         * If the given number has an even number of digits and the number can be
         * divided exactly into two parts from the middle.
         * After equally dividing the number, sum up the numbers and find the square of
         * the sum. If we get the number itself as square, the given number is a tech
         * no, else, not a tech number. For example, 3025 is a tech number.
         */
        int c = countDigits(n);
        return c % 2 == 0 && (int) Math.pow((n / (int) Math.pow(10, c / 2)) + (n % (int) Math.pow(10, c / 2)), 2) == n;
    }

    private boolean isSunny(int n) {
        /*
         * A number is called a sunny number if the number next to the given number is a
         * perfect square.
         * In other words, a number N will be a sunny number if N+1 is a perfect square.
         */
        return Math.sqrt(n + 1) - Math.floor(Math.sqrt(n + 1)) == 0;
    }

    private boolean isCorona(int n) {
        // A number whose all digits are odd.
        for (int digit : getDigits(n))
            if (digit % 2 == 0)
                return false;
        return true;
    }

    private boolean isArmstrong(int n) {
        /*
         * Armstrong number is in which the the sum of the
         * cubes of the all digits is equal to to the number itself.
         * For Example => 153 where (1*1*1)+(5*5*5)+(3*3*3) = 153
         */
        int sum = 0;
        for (int digit : getDigits(n))
            sum += (int) Math.pow(digit, 3);
        return n == sum;
    }

    private boolean isPalindrome(int n) {
        return reverse(n) == n;
    }

    private static int getLcm(int a, int b) {
        for (int i = Math.min(a, b); i <= a * b; i++)
            if (i % a == 0 && i % b == 0)
                return i;
        return a * b;
    }

    private static int getHcf(int a, int b) {
        for (int i = Math.min(a, b); i >= 1; i--)
            if (a % i == 0 && b % i == 0)
                return i;
        return 1;
    }

    private static int countDigits(int n) {
        // int c = 0;
        // while (n != 0) {
        // c++;
        // n /= 10;
        // }
        // return c;
        return getDigits(n).length;
    }

    private static int[] getDigits(int n) {
        ArrayList<Integer> digits = new ArrayList<>();
        while (n != 0) {
            digits.add(n % 10);
            n /= 10;
        }
        return digits.stream().mapToInt(Integer::intValue).toArray(); // .mapToInt(i -> i).toArray();
    }

    private int removeZeros(int n) {
        // for (i = n; i != 0; i = i / 10) r = i % 10 != 0 ? r * 10 + i % 10 : r; //
        // reverse after removing zeros
        for (int digit : getDigits(n))
            n = digit != 0 ? n * 10 + digit : n;
        return n;
    }

    private static int reverse(int n) {
        int rev = 0;
        while (n > 0) {
            rev = rev * 10 + n % 10;
            n /= 10;
        }
        return rev;
    }

    /**
     * @param n
     * @return int. array containing sum of digits at even & odd positions
     * at index 0 and 1 respectively
     */
    private int[] getSumOfDigitsAtEvenAndOddPositions(int n) {
        int i = 1, sumEven = 0, sumOdd = 0;
        for (int digit : getDigits(n)) {
            if (i % 2 == 0)
                sumEven += digit;
            else
                sumOdd += digit;
            i++;
        }
        return new int[]{sumEven, sumOdd};
    }

    private int[] cycleDigits(int n) {
        int[] allPossibleCycles = new int[countDigits(n)];
        for (int i = 0; i < allPossibleCycles.length; i++) {
            allPossibleCycles[i] = n;
            // n = (n % (int) Math.pow(10, countDigits(n) - 1)) * 10 + n / (int)
            // Math.pow(10, countDigits(n) - 1); // first -> last
            n = (n % 10) * (int) Math.pow(10, countDigits(n) - 1) + n / 10; // last -> first
        }
        return allPossibleCycles;
    }

    private int getSumOfFirstAndLastDigits(int n) {
        if (n < 10) // if n is a single digit number
            return n; // return the number itself
        return n % 10 + n / (int) Math.pow(10, countDigits(n) - 1);
    }

    private void getSumOfDigitsFromBothEndsRespectively(int n) {
        int num = n, reverse = reverse(n), c = countDigits(n);
        while (c != 0) {
            System.out.println(num % 10 + " + " + reverse % 10 + " = " + (num % 10 + reverse % 10));
            num /= 10;
            reverse /= 10;
            c = c - 2;
        }
    }

    private int[] getLuckyNumbers(n) {
        String num = "";
        for (int i = 1; i <= n; i += 2) {
            num += i + (i >= n - 1 ? "" : ",");
        }
        for (int i = 2, j = 2; i < num.split(",").length - 1; j += i) {
            if (j >= num.split(",").length) {
                i++;
                j = i;
            }
            String[] arr = num.split(",");
            arr[j] = "x";
            num = String.join(",", arr).replace(",x", "");
            System.out.println("-> " + num);
        }
        System.out.println("Lucky numbers are: " + num);
    }

    private void run(Number_Ops obj_param) {
        System.out.println("");
    }

    public static void main(String[] args) {
        Number_Ops obj = new Number_Ops();
        obj.input();
        Number_Ops myObj = new Number_Ops();
        myObj.run(obj);
    }

    private void input() {
        System.out.println("Enter a number:");
        a = sc.nextInt();
        System.out.println("Enter a number, again:");
        b = sc.nextInt();
    }
}
