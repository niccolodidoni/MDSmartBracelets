#include "smartBracelet.h"

generic configuration KineticSensorC() {

	provides interface Read<kinematic_status_t>;

} implementation {

	components MainC, RandomC;
	components new KineticSensorP();
	components new TimerMilliC();

	//Connects the provided interface
	Read = KineticSensorP;

	//Random interface and its initialization
	KineticSensorP.Random -> RandomC;
	RandomC <- MainC.SoftwareInit;

	//Timer interface
	KineticSensorP.Timer0 -> TimerMilliC;

}
