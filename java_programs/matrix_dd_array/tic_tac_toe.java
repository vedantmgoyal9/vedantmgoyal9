package matrix_dd_array;

public class tic_tac_toe {
    private static java.util.Scanner sc = new java.util.Scanner (System.in);
    private static byte mode = 0, p = 0;
    private static char[][] arr = {
            { '1', '2', '3' },
            { '4', '5', '6' },
            { '7', '8', '9' }
    };
    private static byte[][] pos = {
            { 0, 0 },
            { 0, 1 },
            { 0, 2 },
            { 1, 0 },
            { 1, 1 },
            { 1, 2 },
            { 2, 0 },
            { 2, 1 },
            { 2, 2 }
    };

    public static void main(String[] args) {
        System.out.println("Tic Tac Toe");
        System.out.println("You/Player 1: X");
        System.out.println("Computer/Player 2: O");
        System.out.println("Whom do you want to play first?");
        System.out.println("1. Your friend (2-player mode)");
        System.out.println("2. Computer (1-player mode)");
        System.out.println("Enter your choice: ");
        do {
            mode = sc.nextByte();
            if (mode != 1 && mode != 2)
                System.out.println("Invalid choice. Enter again: ");
        } while (mode != 1 && mode != 2);
        game: while (true) { // labelled loop
            printBoard();
            do {
                System.out.println("(Player 1) Enter position: ");
                p = sc.nextByte();
                if (checkMove(p)) {
                    arr[pos[p - 1][0]][pos[p - 1][1]] = 'X'; // write to array
                    break;
                } else
                    System.out.println("Invalid position! Enter again.");
            } while (!checkMove(p)); // exit when false
            switch (getMatchStatus()) {
                case PLAYER1_WON:
                case PLAYER2_WON:
                case DRAW:
                    break game; // break out of the labelled loop
                case IN_PROGRESS:
                default:
                    break; // do nothing
            }
            printBoard();
            do {
                switch (mode) {
                    case 1:
                        System.out.println("(Player 2) Enter position: ");
                        p = sc.nextByte();
                        break;
                    case 2:
                        System.out.println("Computer's turn...");
                        //p = calculateComputerMove();
                        try {
                            Thread.sleep(800);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                        break;
                }
                if (checkMove(p)) {
                    arr[pos[p - 1][0]][pos[p - 1][1]] = 'O'; // write to array
                    break;
                } else
                    System.out.println("Invalid position! Enter again.");
            } while (!checkMove(p)); // exit when false
            switch (getMatchStatus()) {
                case PLAYER1_WON:
                case PLAYER2_WON:
                case DRAW:
                    break game; // break out of the labelled loop
                case IN_PROGRESS:
                default:
                    break; // do nothing
            }
        }
    }

    // private static byte calculateComputerMove() {
    //     if (arr[0][0]) 
    //     for (byte i = 1; i <= 9; i++)
    //         if (checkMove(i)) {
    //             arr[pos[i - 1][0]][pos[i - 1][1]] = 'O';
    //             if (getMatchStatus() == MatchStatus.PLAYER2_WON) {
    //                 arr[pos[i - 1][0]][pos[i - 1][1]] = Byte.toString(i).charAt(0);
    //                 return i;
    //             }
    //         }
    // }


    private static boolean checkMove(byte p) {
        if (p < 1 || p > 9)
            return false;
        return Character.isDigit(arr[pos[p - 1][0]][pos[p - 1][1]]);
    }

    private static void printBoard() {
        System.out.flush();
        System.out.println(" " + arr[0][0] + " | " + arr[0][1] + " | " + arr[0][2]);
        System.out.println("---+---+---");
        System.out.println(" " + arr[1][0] + " | " + arr[1][1] + " | " + arr[1][2]);
        System.out.println("---+---+---");
        System.out.println(" " + arr[2][0] + " | " + arr[2][1] + " | " + arr[2][2]);
    }

    private static enum MatchStatus {
        PLAYER1_WON, PLAYER2_WON, DRAW, IN_PROGRESS
    }

    private static MatchStatus getMatchStatus() {
        if ((arr[1][1] == 'X' && ((arr[0][0] == 'X' && arr[2][2] == 'X') ||
                (arr[0][2] == 'X' && arr[2][0] == 'X') ||
                (arr[0][1] == 'X' && arr[2][1] == 'X') ||
                (arr[1][0] == 'X' && arr[1][2] == 'X')))
                || (arr[0][0] == 'X' && ((arr[0][1] == 'X' && arr[0][2] == 'X') ||
                        (arr[1][0] == 'X' && arr[2][0] == 'X')))
                || (arr[2][2] == 'X' && ((arr[2][0] == 'X' && arr[2][1] == 'X') ||
                        (arr[0][2] == 'X' && arr[1][2] == 'X')))) {
            System.out.println("Player 1 won!");
            return MatchStatus.PLAYER1_WON;
        }
        if ((arr[1][1] == 'O' && ((arr[0][0] == 'O' && arr[2][2] == 'O') ||
                (arr[0][2] == 'O' && arr[2][0] == 'O') ||
                (arr[0][1] == 'O' && arr[2][1] == 'O') ||
                (arr[1][0] == 'O' && arr[1][2] == 'O')))
                || (arr[0][0] == 'O' && ((arr[0][1] == 'O' && arr[0][2] == 'O') ||
                        (arr[1][0] == 'O' && arr[2][0] == 'O')))
                || (arr[2][2] == 'O' && ((arr[2][0] == 'O' && arr[2][1] == 'O') ||
                        (arr[0][2] == 'O' && arr[1][2] == 'O')))) {
            System.out.println("Player 2 won!");
            return MatchStatus.PLAYER2_WON;
        }
        for (byte i = 1; i < 3; i++)
            for (byte j = 1; j < 3; j++)
                if (arr[i][j] != 'X' && arr[i][j] != 'O')
                    return MatchStatus.IN_PROGRESS;
        System.out.println("It's a draw!");
        return MatchStatus.DRAW;
    }
}
