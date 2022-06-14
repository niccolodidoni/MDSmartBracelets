#include "smartBracelet.h"

generic configuration SensorC() {

	provides interface Read<sensor_data_t>;

} implementation {

	components MainC, RandomC;
	components new SensorP();
	components new TimerMilliC();

	//Connects the provided interface
	Read = SensorP;

	//Random interface and its initialization
	SensorP.Random -> RandomC;
	RandomC <- MainC.SoftwareInit;

	//Timer interface
	SensorP.Timer0 -> TimerMilliC;

}
