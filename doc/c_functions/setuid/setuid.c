/*
 * $Revision: 0.1 $
 * $Date: 2011-06-13 13:27 EDT $
 * vi: ft=c :
 * Luis Mondesi <lemsx1@gmail.com>
 *
 * DESCRIPTION: A simple demonstration of a setuid program
 * USAGE:
 *
 * Compile and run with:
 * gcc -o setuid setuid.c
 * sudo chown root setuid
 * sudo chmod u+s setuid
 * ./setuid
 *
 * LICENSE: GPL
 */
#include <stdio.h>              /* printf */
#include <locale.h>             /* setlocale */

int
main(argc, argv, envp)
int argc;
char *argv[];
char *envp[];
{
    setlocale(LC_ALL,"C"); // change to desired locale; this is to avoid mishandling of char byte sizes.
    if (geteuid() != 0)
    {
        printf("must be setuid root (Effective UID: %d)\n",geteuid ());
        return 1;
    }
    printf(
        "Real      UID = %d\n"
        "Effective UID = %d\n"
        "Real      GID = %d\n"
        "Effective GID = %d\n",
        getuid (),
        geteuid(),
        getgid (),
        getegid()
    );
    return 0;
}

