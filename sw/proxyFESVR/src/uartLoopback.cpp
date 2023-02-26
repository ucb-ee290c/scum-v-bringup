/** A simple UART ascii packet reflector to test if the driver is working.
    FPGA configured to loopback UART signal.

    Modified based upon the demo in rs232 library. 

    Compile: $ make uartLoopback
    Run: $ ./uartLoopback PORT_NUM
*/

/* result: 
sent: The quick brown fox jumped over the lazy grey dog.

received 51 bytes: The quick brown fox jumped over the lazy grey dog.

sent: Happy serial programming!

received 26 bytes: Happy serial programming!
...
*/

#include <stdlib.h>
#include <cstdlib>
#include <stdio.h>
#include <string.h>

#ifdef _WIN32
#include <Windows.h>
#else
#include <unistd.h>
#endif

#include "../rs232/Rs232.h"

int main(int argc, char* argv[]) {
    int i = 0;
    int cPortNr; /* 0: /dev/ttyS0 (COM1 on windows); 17: /dev/ttyUSB1 */
    if (argc == 2) {
        cPortNr = atoi(argv[1]);
    }
    
    int bdrate = 3000000; /* 3000000 baud */
    char mode[] = {'8', 'N', '1', 0};

    constexpr size_t strLen = 512;
    char str[2][strLen];

    constexpr size_t bufLen = 4096;
    unsigned char buf[bufLen];

    strncpy(str[0], "The quick brown fox jumped over the lazy grey dog.\n", strLen);
    strncpy(str[1], "Happy serial programming!\n", strLen);

    if (rs232::openComport(cPortNr, bdrate, mode, 0)) {
        printf("Can not open comport %i\n", cPortNr);
        return 0;
    }

    while (1) {
        rs232::cputs(cPortNr, str[i]);
        printf("sent: %s\n", str[i]);
        i++;
        i %= 2;
        
#ifdef _WIN32
        Sleep(1000);
#else
        usleep(1000000); /* sleep for 1 Second */
#endif

        int n = rs232::pollComport(cPortNr, buf, bufLen - 1);

        if (n > 0) {
            buf[n] = 0; /* always put a "null" at the end of a string! */

            for (int j = 0; j < n; j++) {
                if (buf[j] < 32 && buf[j] != 10) /* replace unreadable control-codes by "*", except newline */ {
                    buf[j] = '*';
                }
            }

            printf("received %i bytes: %s\n", n, (char *) buf);
        }
        
    }

    return 0;
}
