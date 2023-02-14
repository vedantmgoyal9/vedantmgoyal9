package matrix_dd_array;

public class puzzle_game {
    public static void main(String[] args) {
        java.util.Scanner sc = new java.util.Scanner(System.in);
        int[][] arr = new int[3][3];
        // fill the array with random numbers from 1 to 8 with no duplicates
        
        for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 3; j++)
                try {
                System.out.print(arr[i][j] + " ");
                } catch (ArrayIndexOutOfBoundsException e) {
                    System.out.print(" ");
                }
            System.out.println();
        }
    }
}
