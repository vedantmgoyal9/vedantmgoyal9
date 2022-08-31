import static java.lang.System.exit;
public class SimpleBot {
  private static final java.util.Scanner scanner = new java.util.Scanner(System.in);
  public static void main(String[] args) {
    greet("SimpleBot", "2021"); // passing the variable in the method
    remindName(); // calling different methods
    guessAge();
    count();
    test();
  }
  private static void greet(String assistantName, String birthYear) {
    System.out.println("Hello! I am " + assistantName + ".");
    System.out.println("I was created in " + birthYear + ".");
    System.out.println("Please, remind me your name.");
  }
  private static void remindName() {
    System.out.print(">");
    String name = scanner.nextLine();
    System.out.println("What a great name you have, " + name + "!");
  }
  private static void guessAge() {
    System.out.println("Let me guess your age.");
    System.out.println("Say me remainders of dividing your age by 3, 5 and 7.");
    System.out.print(">");
    int rem3 = scanner.nextInt();
    System.out.print(">");
    int rem5 = scanner.nextInt();
    System.out.print(">");
    int rem7 = scanner.nextInt();
    int age = (rem3 * 70 + rem5 * 21 + rem7 * 15) % 105; // formula for age
    System.out.println("Your age is " + age + "; that's a good time to start programming!");
  }
  private static void count() {
    System.out.println("Now I will prove to you that I can count to any number you want.");
    System.out.print(">");
    int num = scanner.nextInt();
    for (int i = 0; i <= num; i++) {
      System.out.printf("%d!\n", i); // using printf()
    }
  }
  private static void test() {
    System.out.println("Let's test your programming knowledge.");
    // write your code here
    System.out.println("Why do we use methods?");
    System.out.println("1. To repeat a statement multiple times.");
    System.out.println("2. To decompose a program into several small subroutines.");
    System.out.println("3. To determine the execution time of a program.");
    System.out.println("4. To interrupt the execution of a program.");
    check();
  }
  private static void check() {
    System.out.print(">");
    int ans = scanner.nextInt();
    if (ans == 2) {
      end();
    } else {
      System.out.println("Please, try again.");
      check();
    }
  }
  private static void end() {
    System.out.println("Congratulations, have a nice day!");
    exit(0);
  }
}
