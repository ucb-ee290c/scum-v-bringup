#include "fesvr.h"
#include <string.h>

#define TEST_PATTERN 0xBBADCAFE

int main() {
    /* Configure with OsciBear Memory Parameters & comport
     * FesvrFpgaUart(uint8_t z, uint8_t o, uint8_t a, uint8_t w, unsigned comport, int brate);
     * Comport designation see: https://github.com/FlorianBauer/rs232
     */
    unsigned comport = 11; // COM12
    int baudrate = 19200;
    FesvrFpgaUart osci(4, 4, 32, 8, comport, baudrate);
    uint32_t content;
    printf("Resetting adapter and flushing RXTX\n");
    // Disable test mode, this is for internal FPGA logic testing. 
    osci.setLoopback(false);
    osci.reset();

    printf("Begin program...\n");
    // This is useful if you want to halt to debug a specific TSI command on the FPGA
    // Wait until the prompt appears the set ILA trigger on FPGA high to observe the packet. 
    printf("Press enter to continue...");
    getchar(); 
    /*  Usable Functions: 
        int read(size_t addr, size_t *content, size_t size);
        int write(size_t addr, size_t *content, size_t size);
        virtual size_t read(size_t addr);
        virtual int write(size_t addr, size_t content);
        int loadElf(char* file, size_t addr);
        int run(size_t addr);
    */
    
    /* Exercise 1 */
    for (size_t i = 0; i < 4; i++) {
        content = osci.read(BOOTROM_BASE + 4*i);
        printf("Read at BOOTROM_BASE + %lX complete, recieved 0x%X \n", i*4, content);
    }
    for (size_t i = 0; i < 4; i++) {
        content = osci.read(DTIM_BASE + 4*i);
        printf("Read at DTIM_BASE + %lX complete, recieved 0x%X \n", i*4, content);
    }
    

    /* Excecise 2: replace the following code with a visual bell. */
    printf("Toggling GPIO 0 pin high \n");
    osci.write(GPIO_BASE + 0xC, 1);
    osci.write(GPIO_BASE + 0x8, 1);

    /* Excercise 3: Running program */
    printf("Setting flag at DTIM_RET \n");
    osci.write(DTIM_RET, 0);
    printf("Trying to read back to confirm results \n");
    content = osci.read(DTIM_RET);
    printf("Read %X from DTIM_RET \n", content);

    //printf("Loading and running... \n");
    //loadElf(&osci, "../osci/firmware.bin", DTIM_BASE);
    //run(&osci);

    content = 0;
    while (content == 0) {
        #ifdef _WIN64 || _WIN32
        Sleep(1);
        #else
        sleep(1);
        #endif
        content = osci.read(DTIM_RET);
        printf("Poll got %X\n", content);
    }

    printf("Finished running, got %X \n", content);
    //printf("%X \n", osci.read(DTIM_RET + 4));
    // When multithreading, these ret pointers are at the next word.

    //FesvrFpgaUart bearly(4, 4, 35, 8, 18, 2000000);
    
}