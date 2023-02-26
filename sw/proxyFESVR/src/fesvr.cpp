#include "tsi.h"
#include "fesvr.h"

#include <stdlib.h>
#include <cstdlib>
#include <stdio.h>

int read(FesvrFpgaUart *svr, size_t addr, uint32_t *content, size_t size) {
    for (size_t i = 0; i < size; i++) {
        content[i] = svr->read(addr + (i*4));
    }
    return 0;
}

int write(FesvrFpgaUart *svr, size_t addr, uint32_t *content, size_t size) {
    for (size_t i = 0; i < size; i++) {
        svr->write(addr + (i*4), content[i]);
    }
    return 0;
}

int loadElf(FesvrFpgaUart *svr, char* filename, size_t addr) {
    FILE* pFile;
    uint32_t buffer;
    uint32_t checkBuffer;
    pFile = fopen(filename, "r");

    size_t addr_i = addr;
    if (pFile == NULL) perror("Error opening file");
    else {
        while (!feof(pFile)) {
            size_t txSize = fread(&buffer, sizeof(buffer), 1, pFile);
            if (txSize == 0u) break;
            svr->write(addr_i, (size_t)buffer);
            if (addr_i % 256 == 0) {
                printf("%X %X\n", addr_i, !feof(pFile));
            }
            addr_i += sizeof(buffer);
        }
        fclose(pFile);
        printf("Done\n");
    }
    printf("Checking results \n");
    /*
    pFile = fopen(filename, "r");
    addr_i = addr;
    if (pFile == NULL) perror("Error opening file");
    else {
        while (!feof(pFile)) {
            //printf("Writing file\n");
            size_t txSize = fread(&buffer, sizeof(buffer), 1, pFile);
            //printf("Got %ld bytes\n", txSize);
            if (txSize == 0u) break;
            //printf("Writing tx\n");
            checkBuffer = svr->read(addr_i);
            if (buffer != checkBuffer) {
                printf("Warning in loadElf %X != %X\n", buffer, checkBuffer);
            }
            addr_i += sizeof(buffer);
            if (addr_i % 256 == 0) {
                printf("%X %X\n", addr_i, !feof(pFile));
            }
        }
        fclose(pFile);
        printf("Done\n");
    }
    */
    return 0;
}

int run(FesvrFpgaUart *svr) {
    printf("WRITING INTO CLINT_BASE... ");
    svr->write(CLINT_BASE, 0xFFFF);
    printf("If the program has begin running, this should be 0:  0x%X \n", svr->read(CLINT_BASE));
    return 0;
}

FesvrFpgaUart::FesvrFpgaUart(uint8_t z, uint8_t o, uint8_t a, uint8_t w, unsigned comport, int brate) {
    port = new TsiFpgaUart(z, o, a, w, comport, brate);

}

size_t FesvrFpgaUart::read(size_t addr) {
    struct TsiPacket tx, rx;
    tx.type = TsiMsg::Get;
    tx.size = 2u;
    tx.source = 0u;
    tx.mask = 0b00001111u;
    tx.corrupt = false;
    tx.last = true;
    tx.addr = addr;
    tx.data = 0u;
    port->setLoopback(loopbackEn);
    //printf("Read serializing, loopback: %b\n", loopbackEn);
    port->serialize(tx);
    // disable response check, FPGA not working rn
    printf("Read deserializing\n");
    rx = port->deserialize();
    if (loopbackEn) {
        //printf("Read deserializing\n");
        //rx = port->deserialize();
        if (!(rx == tx)) {
            printf("Error: fesvr's driver: Loopback failed.\n");
            //printf("rx: %lx, %lx, %lx, %lx, %lx, %lx, %lx, %lx\n", rx.rawHeader, rx.size, rx.source, rx.mask, rx.corrupt, rx.last, rx.addr, rx.data);
            //printf("tx: %lx, %lx, %lx, %lx, %lx, %lx, %lx, %lx\n", tx.rawHeader, tx.size, tx.source, tx.mask, tx.corrupt, tx.last, tx.addr, tx.data);
        } else {
            printf("Loopback read success.\n");
        }
    } else if (rx.type != TsiMsg::AccessAckData) {
        
        printf("Error: Get did not respond with AccessAckData\n!");
    }
    return rx.data;
}

int FesvrFpgaUart::write(size_t addr, size_t content) {
    struct TsiPacket tx, rx;
    // For Osci use PutPartialData
    // Unknown for Bearly & SCUM
    tx.type = TsiMsg::PutPartialData;
    tx.size = 2u;
    tx.source = 0u;
    tx.mask = 0b00001111u;
    tx.corrupt = false;
    tx.last = true;
    tx.addr = addr;
    tx.data = content;
    port->setLoopback(loopbackEn);
    //printf("Writing \n");
    // disable response check, FPGA not working rn
    port->serialize(tx);
    rx = port->deserialize();
    if (loopbackEn) {
        //port->serialize(tx);
        //rx = port->deserialize();
        if (!(rx == tx)) {
            printf("Error: fesvr's driver: Loopback failed.\n");
        } else {
            printf("Loopback write success.\n");
        }
    } else if (rx.type != TsiMsg::AccessAck) {
        printf("Error: PutFullData did not respond with AccessAck\n");
    }
    return 0;
}

void FesvrFpgaUart::reset() {
    port->reset();
}

/*
int FesvrFpgaUart::loadElf(char* filename, size_t addr) {
    return Fesvr::loadElf(filename, addr);
}

int FesvrFpgaUart::run() {
    return Fesvr::run();
}
*/