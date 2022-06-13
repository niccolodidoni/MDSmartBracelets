#include "smartBracelet.h"
#include "printf.h"

generic module PositionSensorP() {

	provides interface Read<pos_t>;

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
		pos_t position;
		position.x = call Random.rand16();
		position.y = call Random.rand16();

		dbg("position_sensor", "POSITION READ: {x=%d, y=%d}\n", position.x, position.y);
		printf("POSITION READ: {x=%d, y=%d}\n", position.x, position.y);
		printfflush();
		signal Read.readDone( SUCCESS, position );
	}
}
