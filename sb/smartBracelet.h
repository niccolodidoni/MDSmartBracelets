#ifndef SMARTBRACELET_H
#define SMARTBRACELET_H

//kinematic status
//typedef enum kinematic_status{
//	STANDING,
//	WALKING,
//	RUNNING,
//	FALLING
// } kinematic_status_t;

#define STANDING 0
#define WALKING 1
#define RUNNING 2
#define FALLING 3

typedef uint8_t kinematic_status_t; 

typedef struct pos {
	nx_uint16_t x;
	nx_uint16_t y;
} pos_t;

//payload of the msg
typedef nx_struct my_msg {
	nx_uint8_t key[21];
	nx_uint8_t msg_type;

	nx_uint16_t x;
	nx_uint16_t y;
	nx_uint8_t kinematic_status;
} my_msg_t;

//msg type
#define PAIRING 1
#define INFO 2

//preloaded keys
static const char KEYS[][21] = {
				"j2GV2SEI81x2CHxYNWSf",
				"gEI5w1YtC5DDEfGT1tNk",
				"a4Ut8wFuKRH41QHybqFd",
				"f30AJWIVO4XZyvDCH1X0",
				"NvVMBT40DOV39Gj6xnxE",
				"LFoWonpoq6yZh5awz753",
				"7KWU3PAgPSojcQ1J5Vbd",
				"Vj7Shb1NcRuhxj7pcWOO",
				"4lX6kesZKMmT5WcebNrB",
				"OGmKTeqwdV9n6wwObR5V"};
				

enum{
AM_MY_MSG = 6,
};

#endif
