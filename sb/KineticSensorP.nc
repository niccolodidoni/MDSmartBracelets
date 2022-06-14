#include "smartBracelet.h"

#define STANDING_UPPER 19660u
#define WALKING_UPPER 39321u
#define RUNNING_UPPER 58981u
#define FALLING_UPPER 65535u

generic module KineticSensorP() {

	provides interface Read<kinematic_status_t>;

	uses interface Random;
	uses interface Timer<TMilli> as Timer0;

} implementation {

	//***************** Boot interface ********************//
	command error_t Read.read(){
		call Timer0.startOneShot( 10 );
		return SUCCESS;
	}

	//***************** Timer0 interface ********************//
	event void Timer0.fired() {
        // using division to map the interval [0, 65535] is more elegant but
        // using directly hand computed intervals from 0 to 2^16 - 1 is more
        // efficient.
        kinematic_status_t status;
        uint16_t num;

        num = call Random.rand16();
        dbg("kinetic_sensor", "RANDOM VALUE READY: %d\n", num);

        status = FALLING;
        if ( 0 <= num && num <= STANDING_UPPER ) {
            status = STANDING;
        } else if ( STANDING_UPPER < num && num <= WALKING_UPPER ) {
            status = WALKING;
        } else if ( WALKING_UPPER < num && num <= RUNNING_UPPER ) {
            status = RUNNING;
        }

        dbg("kinetic_sensor", "VALUE READ: %d\n", status);
        signal Read.readDone( SUCCESS, status );
	}
}
