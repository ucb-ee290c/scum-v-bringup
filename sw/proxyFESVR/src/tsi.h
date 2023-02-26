#ifndef TSI_H
#define TSI_H
#include <stdlib.h>
#include <cstdint>
#include <mutex>

#ifdef _WIN32
#include <Windows.h>
#else
#include <unistd.h>
#endif

/** 
 * TSI Header for the all the known valid TSI messages. 
 * Header is always 9 bits in TSI implementing TL 1.8.0
 * header contains: chanid (3), opcode (3), param (3)
 * param is always 0 for any channel A & D message
 **/ 
// A, 4, 0
#define TSI_HEADER_GET 0b000100000u
// D, 1, 0
#define TSI_HEADER_ACCESSACKDATA 0b011001000u
// A, 0, 0
#define TSI_HEADER_PUTFULLDATA 0b000000000u
// A, 1, 0
#define TSI_HEADER_PUTPARTIALDATA 0b000001000u
// D, 0, 0
#define TSI_HEADER_ACCESSACK 0b011000000u
#define TSI_HEADER_LEN 9u
#define TSI_UART_BDRATE 2000000 /* 2000000 baud */

enum class TsiMsg {Get, AccessAckData, PutFullData, PutPartialData, AccessAck, Unknown};
//enum TestMode {swLoopback, hwLoopback, oneWay};

/* TsiPacket is the packet that is not serialized, should max size in 64 bit RISC-V cores. 
 */
struct TsiPacket {
    TsiMsg type;
    // rawHeader is only used for deserialization debug if TsiMsg is Unk.
    uint16_t rawHeader;
    uint8_t size;
    uint16_t source;
    uint8_t mask;
    bool corrupt;
    bool last;
    uint64_t addr;
    uint64_t data;
};

/**
 * TSI packet assembler and deassembler classes
 * As TSI only supports channel A & D currently under TL-UL, 
 * the parameter i for sink ID is ignored, it is only used when replying in channel E. 
 * TSI implementation relies heavily on the packet assembly order chisel generates, 
 * and there is zero backwards compatibility as it is not formally speced.
 * 
 * DO NOT EXPECT ANY BACKWARDS COMPATIBILITY IF TSI/TL PROTOCOL UPDATES
 * Legal messages (works both way, although for Osci it is one way):
 * Message          | Operation | OpCode| Response
 * Get           (A)| Get       | 4     | AccessAckData
 * AccessAckData (D)| Get/Atomic| 1     | N/A
 *
 * PutFullData   (A)| Put       | 0     | AccessAck (must have contiguous mask)
 * PutPartialData(A)| Put       | 1     | AccessAck (may have partial mask)
 * AccessAck     (D)| Put       | 0     | N/A
 * 
 **/

// Abstract TSI class to provide polymorphism so FESVR can call even with different drivers/protocols. 
// Not a thread safe impl yet. 
class Tsi {
    public:
        // Returns actual packet length in # of bits.
        virtual size_t bufferBitLength() = 0;

        // Returns minimum buffer length in # of bytes. 
        virtual size_t bufferByteLength() = 0;

        virtual int serialize(TsiPacket packet) = 0;
        virtual TsiPacket deserialize() { return TsiPacket(); };
};

/**
 * TsiFpgaUart is the driver for TSI adapters implemented on FPGA, linked by an UART.
 * FESVR is running on an actual host and not a softcore. 
 **/
class TsiFpgaUart : public Tsi {
    public:
        // Constructor configures TSI properly.
        TsiFpgaUart(uint8_t zi, uint8_t oi, uint8_t ai, uint8_t wi, unsigned comport, int brate);

        // Returns actual packet length in # of bits.
        size_t bufferBitLength();
        // Returns expected message length in # of bytes. 
        size_t bufferByteLength();

        int serialize(TsiPacket packet);
        TsiPacket deserialize();
        /** 
         * If loopback test is enabled, drivers wil use internal buffers to simulate. 
         * This is accomplished by having the driver write to readBuffer. 
         */
        void setLoopback(bool en) {loopbackEn = en;}
        void reset();

    private:
        uint8_t z, o, a, w;
        unsigned char pollBuffer[128];
        char writeBuffer[128];
        // Ignore locks for now, all driver functions should be locked later. 
        // std::mutex driverMutex;
        // 
        unsigned comport;
        int baudrate;
        bool loopbackEn;

        int initDriver();
        int pollDriver();
        int writeDriver();
};

// Helper functions generally useful for TSI
uint16_t TsiMsg_getHeader(TsiMsg type);
TsiMsg TsiMsg_getType(uint16_t header);

bool operator==(const TsiPacket& lhs, const TsiPacket& rhs);

bool TsiPacket_isValidMsg(TsiPacket packet);

void put_uint64_into_buffer(uint8_t *buffer, size_t bitOffset, uint64_t data, size_t bits);
uint64_t get_uint64_from_buffer(uint8_t *buffer, size_t bitOffset, size_t bits);

uint64_t getMask(size_t n, size_t m);
void loadBits(uint8_t* dest, uint64_t src, size_t n, size_t m, size_t k);
void getBits(uint64_t* dest, uint8_t src, size_t n, size_t m, size_t k);
uint8_t reverseBits(uint8_t in);

#endif