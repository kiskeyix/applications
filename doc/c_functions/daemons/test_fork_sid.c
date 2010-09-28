/*
 * $Revision: 0.1 $
 * $Date: 2010-09-28 11:58 EDT $
 * vi: ft=c :
 * Luis Mondesi <lemsx1@gmail.com>
 *
 * DESCRIPTION: test session id creation on Linux systems
 * USAGE:
 * LICENSE: GPL
 */
#include <stdio.h>              /* printf */
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>

int
main (int argc, char **argv)
{
        pid_t pid, sid;
        pid = fork();
        if (pid < 0)
        {
            exit(EXIT_FAILURE);
        }
        sid = getsid();
        printf ("parent sid: %d\n", sid);

        /* we tell the parent process to exit */
        if (pid > 0)
        {
            exit(EXIT_SUCCESS);
        }

        /* session ID is inherited from parent */
        sid = getsid();
        printf ("child sid: %d\n", sid);

        sid = setsid();
        if (sid < 0)
        {
            printf("Failed to get new sid for child process\n");
            exit(EXIT_FAILURE);
        }
        printf ("new child sid: %d\n", sid);
        return 0;
}
