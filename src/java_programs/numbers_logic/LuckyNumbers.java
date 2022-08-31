package numbers_logic;
public class LuckyNumbers {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter number till where to find lucky numbers: ");
    String num = "";
    int n = sc.nextInt();
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
    sc.close();
  }
}
