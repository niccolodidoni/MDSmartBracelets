
#ifndef TEST_SERIAL_H
#define TEST_SERIAL_H

typedef nx_struct test_serial_msg {
  nx_uint16_t x;
  nx_uint16_t y; 
  nx_uint8_t alert_type; 
} test_serial_msg_t;

enum {
  AM_TEST_SERIAL_MSG = 0x89,
};

#endif
