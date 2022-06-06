package java_programs.for_loop;

/*
 * WAP to find Armstrong number between 100 to 500.
 * Armstrong number is in which the the sum of the
 * cubes of the all three digits is equal to to the number itself.
 * For Example => 153 where (1*1*1)+(5*5*5)+(3*3*3) = 153
 */
public class Armstrong100to500 {
  public static void main(String[] args) {
    for (int i = 100; i <= 500; i++) {
      int u = i % 10, t = i / 10 % 10, h = i / 100;
      if (i == u * u * u + t * t * t + h * h * h) System.out.println(i);
    }
  }
}
