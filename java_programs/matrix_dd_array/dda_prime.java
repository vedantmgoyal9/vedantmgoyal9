package matrix_dd_array;
public class dda_prime {
    public static int nextPrime(int n) {
        while (true) {
            n++;
            int i = 2;
            while (i <= n/2) {
                if (n % i == 0)
                    break;
                i++;
            }
            if (i == (n / 2) + 1)
                return n;
        }
    }

    public static void main(String[] args) {
        java.util.Scanner sc = new java.util.Scanner(System.in);
        System.out.println("Enter rows of array: ");
        int rows = sc.nextInt();
        System.out.println("Enter columns of array: ");
        int cols = sc.nextInt();
        // Creating and filling array
        int arr[][] = new int[rows][cols], p = 0;
        for (int i = 0; i < rows; i++)
            for (int j = 0; j < cols; j++) {
                p = nextPrime(p);
                arr[i][j] = p;
            }
        // Printing array
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++)
                System.out.print(arr[i][j] + "\t");
            System.out.println();
        }
        sc.close();
    }
}
