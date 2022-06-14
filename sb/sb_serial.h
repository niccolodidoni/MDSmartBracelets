#ifndef SB_SERIAL_H
#define SB_SERIAL_H

// alert types
#define FALL 1
#define MISSING 2
#define TEST 3

typedef nx_struct serial_msg {
	nx_uint8_t alert_type;
  	nx_uint16_t x; 
  	nx_uint16_t y;  
} serial_msg_t;

enum {
  AM_SERIAL_MSG = 0x89,
};

#endif
