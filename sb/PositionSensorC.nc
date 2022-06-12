#include "smartBracelet.h"

generic configuration PositionSensorC() {

	provides interface Read<pos_t>;

} implementation {

	components MainC, RandomC;
	components new PositionSensorP();
	components new TimerMilliC();

	//Connects the provided interface
	Read = PositionSensorP;

	//Random interface and its initialization
	PositionSensorP.Random -> RandomC;
	RandomC <- MainC.SoftwareInit;

	//Timer interface
	PositionSensorP.Timer0 -> TimerMilliC;

}
