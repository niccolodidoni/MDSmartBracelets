#include "TestSerial.h"
#include "smartBracelet.h"

configuration smartBraceletAppC {}

implementation {


/****** COMPONENTS *****/
  components MainC, smartBraceletC as App;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components new TimerMilliC() as TimerMilliC;
  components new TimerMilliC() as Timer10MilliC;
  components new TimerMilliC() as Timer60MilliC;
  components new TimerMilliC() as TimerKeepAliveC;
  components ActiveMessageC;
  components SerialActiveMessageC as SerialAM;

  // Sensor used to read the position of the bracelet.
  // INTERFACES: Read
  components new PositionSensorC();

  // Sensor used to read the kinetic status of the bracelet.
  // INTERFACES: Read
  components new KineticSensorC();

  // Sensor used to read the kinematic status and the position of the bracelet.
  components new SensorC();

/****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Wire the other interfaces down here *****/
  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.Packet -> AMSenderC;
  App.ReceivePacket -> AMReceiverC;
  App.SendPacket -> AMSenderC;
  App.Acks -> ActiveMessageC;

  // Serial communication
  App.SerialSend -> SerialAM.AMSend[AM_TEST_SERIAL_MSG];
  App.SerialPacket -> SerialAM;
  App.SerialSC -> SerialAM;

  //Timer interface
  App.MilliTimer -> TimerMilliC;
  App.Milli10Timer -> Timer10MilliC;
  App.Milli60Timer -> Timer60MilliC;
  App.KeepAliveTimer -> TimerKeepAliveC;

  // Sensor read
  App.PositionRead -> PositionSensorC;
  App.KineticRead -> KineticSensorC;
  App.SensorRead -> SensorC;
}
