#include "tsi.h"
#include "../rs232/Rs232.h"

#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))

TsiFpgaUart::TsiFpgaUart(uint8_t zi, uint8_t oi, uint8_t ai, uint8_t wi, unsigned comport, int brate) {
    z = zi;
    o = oi;
    a = ai;
    w = wi;
    TsiFpgaUart::comport = comport;
    TsiFpgaUart::baudrate = brate;
    if (initDriver() == -1) {
        printf("Fatal error: unable to initialize comport");
        throw "Cannot initialize comport";
    }
    loopbackEn = false;
    baudrate = brate;
}

/* To understand why, see https://github.com/ucberkeley-ee290c/fa22/tree/main/labs/lab2-tsi-flow */
size_t TsiFpgaUart::bufferBitLength() {
    return 3 + 3 + 3 + z + o + a + 9*((size_t)w) + 1 + 1;
}

size_t TsiFpgaUart::bufferByteLength() {
    size_t bitlen = bufferBitLength();
    return bitlen/8u + (((bitlen % 8u) == 0u) ? 0u : 1u);
}

void TsiFpgaUart::reset() {
    // Set full
    rs232::flushRxTx(comport);
    size_t bytes = TsiFpgaUart::bufferByteLength();
    for (size_t i = 0; i < bytes; i++) {
        writeBuffer[i] = 0xFFu;
    }
    // Send it twice in case fpga buffer is in unstable state, guarenteeing reset.
    writeDriver(); writeDriver(); writeDriver(); writeDriver(); 
    writeDriver(); writeDriver(); writeDriver(); writeDriver(); 
    /* sleep for 2 seconds, ensure write is written, then flush all buffers */
    #ifdef _WIN32
        Sleep(2000);
    #else
        usleep(2000000); 
    #endif
    rs232::flushRxTx(comport);
    return;
}

/** 
 * Serializes message given paremeters.
 * Reminder: signal orders and all the actual bits are reversed (as in the whole packet is LSBit).
 * UART is LSBit first already, so just simply reverse the assembly order for the fields. 
 * Recommend working in uint8_t arrays so that there are no endian issues. 
 */
int TsiFpgaUart::serialize(TsiPacket packet) {    
    // Set the buffers to 0.
    size_t bytes = TsiFpgaUart::bufferByteLength();
    for (size_t i = 0; i < bytes; i++) {
        writeBuffer[i] = 0u;
    }
    
    packet.rawHeader = TsiMsg_getHeader(packet.type);
    
    size_t bitOffset = 0u;
    put_uint64_into_buffer((uint8_t*)writeBuffer, bitOffset, packet.last? 0b1u : 0b0u, 1u);
    bitOffset += 1u;
    put_uint64_into_buffer((uint8_t*)writeBuffer, bitOffset, packet.mask, w);
    bitOffset += w;
    put_uint64_into_buffer((uint8_t*)writeBuffer, bitOffset, packet.corrupt ? 0b1u : 0b0u, 1u);
    bitOffset += 1u;
    put_uint64_into_buffer((uint8_t*)writeBuffer, bitOffset, packet.data, w*8u);
    bitOffset += w*8u;
    put_uint64_into_buffer((uint8_t*)writeBuffer, bitOffset, packet.addr, a);
    bitOffset += a;
    put_uint64_into_buffer((uint8_t*)writeBuffer, bitOffset, packet.source, o);
    bitOffset += o;
    put_uint64_into_buffer((uint8_t*)writeBuffer, bitOffset, packet.size, z);
    bitOffset += z;
    put_uint64_into_buffer((uint8_t*)writeBuffer, bitOffset, packet.rawHeader, TSI_HEADER_LEN);
    bitOffset += TSI_HEADER_LEN;
    bytes = (bitOffset/8u + ((bitOffset % 8u) > 0u ? 1u : 0u));

    if (bytes != bufferByteLength()) {
        throw "Internal Tsi error, assembled packet byte length is not expected";
    }
    if (bufferBitLength() != (bitOffset)) {
        throw "Internal Tsi error, assembled packet bit length is not expected";
    }
    /*
    printf("Write Buffer is now: [%lu] 0x", bytes);
    for (size_t i = 0; i < bytes; i++) {
        printf("%02hX ", writeBuffer[i]);
    }
    printf("\n");
    */
    // Defined arguments: size, source, address, data, mask, corrupt(0), last(1);
    // tsimsg msgtype; uint8_t size; uint8_t source; uint32_t address; uint64_t data; uint8_t mask; 

    writeDriver(); 
    return 0;
}

/* Deserialize message and return parameter. 
 * Edge cases (esp if chip can initiate requests): 
 * 1. multiple messages recieved at once will be directed to an internal FIFO class buffer. 
 * 2. recieves a message that is incomplete, in this case, poll again until complete message is recieved. 
 * 3. if both cases above occurs, buffer excess processed packets internally, and buffer incomplete packet.
 * For now, expect fesvr to call serdes only sequentially, meaning only one request may be in flight. 
 * Repeatedly poll until message is decoded, which freezes everything, as TL should behave... 
 */
TsiPacket TsiFpgaUart::deserialize() {
    TsiPacket packet;
    
    pollDriver();

    size_t bitOffset = 0u;

    packet.last = get_uint64_from_buffer((uint8_t*)pollBuffer, bitOffset, 1u) != 0;
    bitOffset += 1u;

    packet.mask = get_uint64_from_buffer((uint8_t*)pollBuffer, bitOffset, w);
    bitOffset += w;
    packet.corrupt = get_uint64_from_buffer((uint8_t*)pollBuffer, bitOffset, 1u) != 0;
    bitOffset += 1u;

    packet.data = get_uint64_from_buffer((uint8_t*)pollBuffer, bitOffset, w*8u);
    bitOffset += w*8u;
    packet.addr = get_uint64_from_buffer((uint8_t*)pollBuffer, bitOffset, a);
    bitOffset += a;
    packet.source = get_uint64_from_buffer((uint8_t*)pollBuffer, bitOffset, o);
    bitOffset += o;
    packet.size = get_uint64_from_buffer((uint8_t*)pollBuffer, bitOffset, z);
    bitOffset += z;
    packet.rawHeader = get_uint64_from_buffer((uint8_t*)pollBuffer, bitOffset, TSI_HEADER_LEN);
    bitOffset += TSI_HEADER_LEN;

    if (bufferBitLength() != bitOffset) { //(expectedBits != (bitOffset - 8u))
        throw "Internal Tsi error, got unexpected packet length";
    }
    /*
    printf("Poll Buffer is now: [%lu] 0x", bufferByteLength());
    for (size_t i = 0; i < bufferByteLength()-1u; i++) {
        printf("%02hX ", pollBuffer[i]);
    }
    printf("\n");
    */

    packet.type = TsiMsg_getType(packet.rawHeader);
    return packet;
}

int TsiFpgaUart::initDriver() {
    char mode[] = {'8', 'N', '1', 0};
    int status = rs232::openComport(comport, baudrate, mode, 0);
    if (status) {
        printf("Can not open comport %i\n", comport);
        printf("Returned error code: %i\n", status);
        throw "Cannot open comport";
        return -1;
    }
    TsiFpgaUart::comport = comport;
    return 0;
}

int TsiFpgaUart::pollDriver() {
    size_t expBytes = bufferByteLength();
    // Hardware loopback enabled
    /*
    if (loopbackEn) {  
        for (size_t i = 0; i < expBytes; i++) {
            pollBuffer[i] = writeBuffer[i];
        }
        return expBytes;
    } else {
        */
        size_t rxBytes = 0u;
        // timeout after 100ms 
        size_t counter = 0u;
        while (rxBytes < expBytes) {
            rxBytes += rs232::pollComport(comport, pollBuffer+rxBytes, expBytes-rxBytes);
            //printf("Polled %lu bytes\n", rxBytes);
            if (counter++ > 100000u && rxBytes == 0) {
                break;
			}

        }
        return rxBytes;
    //}
}

int TsiFpgaUart::writeDriver() {
    //return loopbackEn ? bufferByteLength() : rs232::sendBuf(comport, writeBuffer, bufferByteLength());
    return rs232::sendBuf(comport, writeBuffer, bufferByteLength());
}

// Helper functions generally useful for TSI
uint16_t TsiMsg_getHeader(TsiMsg type) {
    uint16_t header;
    switch(type) {
        case TsiMsg::Get:
            header = TSI_HEADER_GET;
            break;
        case TsiMsg::AccessAckData:
            header = TSI_HEADER_ACCESSACKDATA;
            break;
        case TsiMsg::PutFullData:
            header = TSI_HEADER_PUTFULLDATA;
            break;
        case TsiMsg::PutPartialData:
            header = TSI_HEADER_PUTPARTIALDATA;
            break;
        case TsiMsg::AccessAck:
            header = TSI_HEADER_ACCESSACK;
            break;
        case TsiMsg::Unknown:
            throw "Cannot get header of TsiMsg: Unknown";
            break;
    }
    return header;
}

TsiMsg TsiMsg_getType(uint16_t header) {
    TsiMsg type;
    switch(header) {
        case TSI_HEADER_GET:
            type = TsiMsg::Get;
            break;
        case TSI_HEADER_ACCESSACKDATA:
            type = TsiMsg::AccessAckData;
            break;
        case TSI_HEADER_PUTFULLDATA:
            type = TsiMsg::PutFullData;
            break;
        case TSI_HEADER_PUTPARTIALDATA:
            type = TsiMsg::PutPartialData;
            break;
        case TSI_HEADER_ACCESSACK:
            type = TsiMsg::AccessAck;
            break;
        type = TsiMsg::Unknown;
    }
    return type;
}

// Check if all fields except the rawHeaders are equal.
bool operator==(const TsiPacket& lhs, const TsiPacket& rhs) {
    return (lhs.type == rhs.type) & (lhs.size == rhs.size) &
        (lhs.source == rhs.source) & (lhs.mask == rhs.mask) &
        (lhs.corrupt == rhs.corrupt) & (lhs.last == rhs.last) &
        (lhs.addr == rhs.addr) & (lhs.data == rhs.data);
}

/** 
 * Puts an uint64_t into an uint8_t array buffer.  
 */
void put_uint64_into_buffer(uint8_t *buffer, size_t bitOffset, uint64_t data, size_t bits) {
    size_t data_cnt = 0u;
    //printf("put_uint64_into_buffer\n");
    while (data_cnt < bits) {
        size_t buffer_i = (bitOffset+data_cnt) / 8;
        size_t buffer_j = (bitOffset+data_cnt) % 8;
        size_t step = MIN(bits - data_cnt, 8u - buffer_j);
        //printf("%lu, %lu, %lu, %lu \n", buffer_i, buffer_j, step, data_cnt);
        // buffer[buffer_i][step+buffer_j-1:buffer_j] = data[step+data_cnt-1:data_cnt]
        loadBits(&(buffer[buffer_i]), data, step, buffer_j, data_cnt);
        data_cnt += step;
    }
}

/* Gets an uint64_t from an uint8_t array buffer. */
uint64_t get_uint64_from_buffer(uint8_t *buffer, size_t bitOffset, size_t bits) {
    uint64_t data = 0u;
    size_t data_cnt = 0u;
    while (data_cnt < bits) {
        size_t buffer_i = (bitOffset+data_cnt) / 8;
        size_t buffer_j = (bitOffset+data_cnt) % 8;
        size_t step = MIN(bits - data_cnt, 8u - buffer_j);
        // data[step+data_cnt-1:data_cnt] = buffer[buffer_i][step+buffer_j-1:buffer_j]
        getBits(&data, buffer[buffer_i], step, data_cnt, buffer_j);
        data_cnt += step;
    }
    return data;
}

bool TsiPacket_isValidMsg(TsiPacket packet) {
    return (packet.type != TsiMsg::Unknown) & (!packet.corrupt);
    // Todo: look into the type of message and check if the size and mask makes sense.
}


// Get uint64_t bitmask of result[N+M:M]
uint64_t getMask(size_t n, size_t m) {
    return (n < 63u) ? ((1u << n) - 1) << m : 0xFFu << m;
}

/* load bits: dest[N+M-1:M] = src[N+K-1:K]
 * assumes bits in dest are fully zeroed so this uses or to set
 */
void loadBits(uint8_t* dest, uint64_t src, size_t n, size_t m, size_t k) {
    *dest |= ((src & getMask(n, k)) >> k) << m;
}

/* get bits: dest[N+M-1:M] = src[N+K-1:K]
 * assumes bits in dest are fully zeroed so this uses or to set
 */
void getBits(uint64_t* dest, uint8_t src, size_t n, size_t m, size_t k) {
    *dest |= ((src & getMask(n, k)) >> k) << m;
}

// TSI serializes LSB first and reverses all the fields, this might come in handy...?
// Not used for now, UART apparently is LSBit first.
uint8_t reverseBits(uint8_t in) {
    uint8_t out = 0u;
    for (int i = 0; i < 8; i++) {
        out |= (in & 1ul) << (7-i); 
        in = in >> 1;
    }
    return out;
}
