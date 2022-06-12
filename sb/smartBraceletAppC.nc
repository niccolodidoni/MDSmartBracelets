#include "smartBracelet.h"

configuration smartBraceletAppC {}

implementation {


/****** COMPONENTS *****/
  components MainC, smartBraceletC as App;
  components new AMSender(AM_MY_MSG);
  components new AMReceiver(AM_MY_MSG);
  components new TimerMilliC();
  components new Timer10MilliC();
  components new Timer60MilliC();
  components ActiveMessageC;
  components new FakeSensorC();

/****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Wire the other interfaces down here *****/
  //Send and Receive interfaces
  App.Receive -> AmReceiverC;
  App.AMSend -> AMSenderC;

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.Packet -> AMSenderC;
  App.Acks -> ActiveMessageC;

  //Timer interface
  App.MilliTimer -> TimerMilliC;
  App.MilliTimer10 -> Timer10MilliC;
  App.MilliTimer60 -> Timer60MilliC;

  //Fake Sensor read
  App.Read -> FakeSensorC;

}

