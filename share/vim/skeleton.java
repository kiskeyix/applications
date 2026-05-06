/*
 * my_name < email@example.com >
 *
 * DESCRIPTION:
 * USAGE:
 * LICENSE: ___
 *
 * to compile: javac HelloWorld.java
 * to run: java HelloWorld
 */
import javax.swing.*;

public class HelloWorld extends JFrame {

    public HelloWorld() {
        JLabel l = new JLabel("Hello World");

        this.getContentPane().add(l);
        this.setSize(256, 256);
        this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        this.setVisible(true);
    }

    public static void main(String[] args) {
        HelloWorld r = new HelloWorld();
    }
}
