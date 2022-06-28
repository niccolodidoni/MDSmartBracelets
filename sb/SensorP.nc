#include "smartBracelet.h"

#define STANDING_UPPER 19661u
#define WALKING_UPPER 39322u
#define RUNNING_UPPER 58983u
#define FALLING_UPPER 65535u

generic module SensorP() {

	provides interface Read<sensor_data_t>;

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
        sensor_data_t data; 
        uint16_t num = call Random.rand16() + call Timer0.getNow();

        if ( 0 <= num && num <= STANDING_UPPER ) {
            data.kinematic_status = STANDING;
        } else if ( STANDING_UPPER < num && num <= WALKING_UPPER ) {
            data.kinematic_status = WALKING;
        } else if ( WALKING_UPPER < num && num <= RUNNING_UPPER ) {
            data.kinematic_status = RUNNING;
        } else {
        	data.kinematic_status = FALLING;
        }
        
        data.x = call Random.rand16();
		data.y = call Random.rand16();

        dbg("complete_sensor", "DATA READ: {\n\tkinematic_status=%u\n\tposition=(x=%u, y=%u)\n}\n", data.kinematic_status, data.x, data.y);
        signal Read.readDone( SUCCESS, data );
	}
}
