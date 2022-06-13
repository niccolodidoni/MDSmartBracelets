#define NEW_PRINTF_SEMANTICS 

#include "printf.h"
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
  components ActiveMessageC;

  // serial print
  components SerialPrintfC;
  components SerialStartC;

  // Sensor used to read the position of the bracelet.
  // INTERFACES: Read
  components new PositionSensorC();

  // Sensor used to read the kinetic status of the bracelet.
  // INTERFACES: Read
  components new KineticSensorC();

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
  App.Acks -> ActiveMessageC;

  //Timer interface
  App.MilliTimer -> TimerMilliC;
  App.Milli10Timer -> Timer10MilliC;
  App.Milli60Timer -> Timer60MilliC;

  // Sensor read
  App.PositionRead -> PositionSensorC;
  App.KineticRead -> KineticSensorC;
}