#include "smartBracelet.h"
#include "Timer.h"

module smartBraceletC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	
    //interfaces for communication
	interface Receive;
	interface AMSend;
	interface SplitControl;
	interface Packet;
	interface PacketAcknowledgements as Acks;	

	//interface for timer
	interface Timer<TMilli> as MilliTimer;
	interface Timer<TMilli> as Milli10Timer;
	interface Timer<TMilli> as Milli60Timer;
	
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t counter = 0;
  message_t packet;
  char[21] key;
  am_addr_t src_addr;
  bool locked = FALSE;

  nx_uint16_t x;
  nx_uint16_t y;
  nx_uint8_t kinematic_status;

  //pairing, operation
  nx_uint8_t mode;

  void randomKinematicStatus(){

	//generate random number, normalize 0-0.9
	
	//standing,walking,running
	if(probability < 0.2)
		kinematic_status = STANDING;
	else if(probability < 0.5)
		kinematic_status = WALKING;
	else if(probability < 0.8)
		kinematic_status = RUNNING;
	//falling
	else kinematic_status = FALLING;

  }
  

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	/* Fill it ... */
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
    /* Fill it ... */
  }
  
  event void SplitControl.stopDone(error_t err){
    /* Fill it ... */
  }

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 * Fill this part...
	 */
  }
  
  event void Milli10Timer.fired() {
  
  }
  
  event void Milli60Timer.fired() {
  
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {

  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {


  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
  
  }


}

