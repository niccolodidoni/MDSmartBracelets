#ifndef SMARTBRACELET_H
#define SMARTBRACELET_H

//payload of the msg
typedef nx_struct my_msg {
	char[21] key;
	nx_uint8_t msg_type;

	nx_uint16_t x;
	nx_uint16_t y;
	nx_uint8_t kinematic_status;
} my_msg_t;

//msg type
#define PAIRING 1
#define INFO 2

//preloaded keys
static const char[21] KEYS[] = {"j2GV2SEI81x2CHxYNWSf",
				"gEI5w1YtC5DDEfGT1tNk",
				"a4Ut8wFuKRH41QHybqFd",
				"f30AJWIVO4XZyvDCH1X0",
				"NvVMBT40DOV39Gj6xnxE",
				"LFoWonpoq6yZh5awz753",
				"7KWU3PAgPSojcQ1J5Vbd",
				"Vj7Shb1NcRuhxj7pcWOO",
				"4lX6kesZKMmT5WcebNrB",
				"OGmKTeqwdV9n6wwObR5V"};

//kinematic status
enum{STANDING,WALKING,RUNNING,FALLING};

enum{
AM_MY_MSG = 6,
};

#endif
