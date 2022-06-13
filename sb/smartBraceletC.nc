#define NEW_PRINTF_SEMANTICS

#include "printf.h"
#include "smartBracelet.h"
#include "Timer.h"


module smartBraceletC {

  uses {
  /****** INTERFACES *****/
	interface Boot;

    // interfaces for communication
	interface Receive;
	interface AMSend;
	interface SplitControl;
	interface Packet;
	interface PacketAcknowledgements as Acks;

	// interface for timer
	interface Timer<TMilli> as MilliTimer;
	interface Timer<TMilli> as Milli10Timer;
	interface Timer<TMilli> as Milli60Timer;

	// interface used to perform sensor reading
	interface Read<pos_t> as PositionRead;
    interface Read<kinematic_status_t> as KineticRead;
  }

} implementation {

  uint8_t counter = 0;
  message_t packet;
  char key[21];
  am_addr_t src_addr;
  bool locked = FALSE;

  nx_uint16_t x;
  nx_uint16_t y;
  nx_uint8_t kinematic_status;

  //pairing, operation
  nx_uint8_t mode;


  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	printf("Application booted.\n");
	printfflush();
	call KineticRead.read();
    call PositionRead.read();
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
	return NULL;

  }

    //************************* Read interface **********************//
    event void KineticRead.readDone(error_t result, kinematic_status_t data) {
        dbg("app_kin_sensor", "KINEMATIC STATUS: %d", data);
        printf("KINEMATIC STATUS: %d\n", data);
        printfflush();
    }

    event void PositionRead.readDone(error_t result, pos_t data) {
        dbg("app_kin_sensor", "POSITION: (x=%u, y=%u)\n", data.x, data.y);
        printf("POSITION: (x=%u, y=%u)\n", data.x, data.y);
        printfflush();
    }

}
