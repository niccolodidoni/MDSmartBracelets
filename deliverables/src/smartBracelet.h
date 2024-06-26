#ifndef SMARTBRACELET_H
#define SMARTBRACELET_H

//kinematic status
//typedef enum kinematic_status{
//	STANDING,
//	WALKING,
//	RUNNING,
//	FALLING
// } kinematic_status_t;

// Kinematic status
#define STANDING 0
#define WALKING 1
#define RUNNING 2
#define FALLING 3

typedef uint8_t kinematic_status_t;

typedef struct pos {
	nx_uint16_t x;
	nx_uint16_t y;
} pos_t;

typedef struct sensor_data {
	kinematic_status_t kinematic_status;
	nx_uint16_t x;
	nx_uint16_t y;
} sensor_data_t;

// Bracelet role
#define PARENT 0   	// parent is even
#define CHILD 1		// child is odd


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
#define PAIREND 3
#define KEEP_ALIVE 4

// state type
#define BROADCASTING_STATE 1	// the mote broadcasts pairing messages
#define PAIRING_STATE 2			// the mote has received a pair msg
#define OPERATION_STATE 3		// the mote sends (or receive) info messages


//preloaded keys
static const char KEYS[][21] = {
				"j2GV2SEI81x2CHxYNWSf\0",
				"gEI5w1YtC5DDEfGT1tNk\0",
				"a4Ut8wFuKRH41QHybqFd\0",
				"f30AJWIVO4XZyvDCH1X0\0",
				"NvVMBT40DOV39Gj6xnxE\0",
				"LFoWonpoq6yZh5awz753\0",
				"7KWU3PAgPSojcQ1J5Vbd\0",
				"Vj7Shb1NcRuhxj7pcWOO\0",
				"4lX6kesZKMmT5WcebNrB\0",
				"OGmKTeqwdV9n6wwObR5V\0"};


enum{
AM_MY_MSG = 6,
};



#endif
