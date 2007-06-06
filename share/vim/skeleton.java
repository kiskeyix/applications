/*
 * $Revision: 1.1 $
 * $Date: 2007-06-06 03:12:57 $
 * vi: ft=java :
 * my_name < email@example.com >
 *
 * DESCRIPTION:
 * USAGE:
 * LICENSE: ___
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
