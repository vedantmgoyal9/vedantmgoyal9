package matrix_dd_array;
public class dda_sum_border {
    public static void main (String[] args) {
        java.util.Scanner sc = new java.util.Scanner(System.in);
        System.out.print("Enter size of array: ");
        int[] arr = new int[sc.nextInt()];
        System.out.print("Enter elements of array: ");
        for (int i : arr) {
            i = sc.nextInt();
        }
        System.out.println("Printing elements of array: ");
        for (int i : arr) {
            System.out.print(i + " ");
        }
    }
}
