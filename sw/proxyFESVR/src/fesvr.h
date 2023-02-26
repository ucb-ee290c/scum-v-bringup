#ifndef FESVR_H
#define FESVR_H

#include "tsi.h"

#define DEBUG_CONTROLLER_BASE   0x00000000
#define BOOT_SELECT_BASE        0x00002000
#define ERROR_DEVICE_BASE       0x00003000
#define BOOTROM_BASE            0x00010000
#define TILE_RESET_CTRL_BASE    0x00100000
#define CLINT_BASE              0x02000000
#define PLIC_BASE               0x0C000000
#define LBWIF_RAM_BASE          0x10000000
#define GPIO_BASE               0x10012000
#define QSPI_BASE               0x10040000
#define FLASH_BASE              0x20000000
#define UART_BASE               0x54000000
#define DTIM_BASE               0x80000000
#define DTIM_RET                0x80004000

/* Memory pool virtualization is currently not supported, meaning only host can initiate requests via channel A.
 * Support will be added later by adding a response function that polls and respond. 
 */
class Fesvr {
    public:
        //int read(size_t addr, size_t *content, size_t size);
        //int write(size_t addr, size_t *content, size_t size);
        virtual size_t read(size_t addr) {return 0;};
        virtual int write(size_t addr, size_t content) {return 0;};
        //int loadElf(char* file, size_t addr);
        //int run();
        //int memoryPoll();

};

class FesvrFpgaUart : public Fesvr {
    public:
        FesvrFpgaUart(uint8_t z, uint8_t o, uint8_t a, uint8_t w, unsigned comport, int brate);
        size_t read(size_t addr);
        int write(size_t addr, size_t content);
        void setLoopback(bool en) {loopbackEn = en;};
        void reset();
        //int loadElf(char* file, size_t addr);
        //int run();
        
    private:
        TsiFpgaUart* port;
        bool loopbackEn;
};

int read(FesvrFpgaUart *svr, size_t addr, uint32_t *content, size_t size);
int write(FesvrFpgaUart *svr, size_t addr, uint32_t *content, size_t size);
int loadElf(FesvrFpgaUart *svr, char* file, size_t addr);
int run(FesvrFpgaUart *svr);

#endif