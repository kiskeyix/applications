/* Luis Mondesi <lemsx1@gmail.com> 
 * Playing around with Java
 *
 * to compile: javac HelloWorld.java
 * to run: java HelloWorld (no need for .class)
 */
import javax.swing.*;

public class HelloWorld extends JFrame {

    public HelloWorld () {
        JLabel l = new JLabel ("Hello World");

        this.getContentPane().add(l);
        this.setSize(256, 256);

        //this.pack();
        this.setVisible (true);
    }

    public static void
        main (String args[]) {
            HelloWorld r = new HelloWorld ();
        }

}
