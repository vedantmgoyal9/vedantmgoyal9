public class SumFirstLast {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter no. of blocks of array: ");
    int n = sc.nextInt(), arr[] = new int[n];
    for (int i = 0; i < n; i++) {
      System.out.println("Enter value for " + i + " block of array: ");
      arr[i] = sc.nextInt();
    }
    System.out.println("Sum of numbers are:");
    for (int i = 0; i < (arr.length % 2 == 0 ? arr.length / 2 : arr.length / 2 + 1); i++, n--)
      System.out.println(arr[i] + "+" + arr[n - 1] + "=" + (arr[i] + arr[n - 1]));
    sc.close();
  }
}
