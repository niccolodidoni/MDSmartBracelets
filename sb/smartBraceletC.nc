#include "smartBracelet.h"
#include "Timer.h"

#define PAIRING_TIME 30000


module smartBraceletC {

  uses {
  /****** INTERFACES *****/
	interface Boot;

    // interfaces for communication
	interface Receive;
	interface AMSend;
	interface SplitControl;
	interface Packet;
	interface AMPacket as SendPacket; 
	interface AMPacket as ReceivePacket; 

	// interface for timer
	interface Timer<TMilli> as MilliTimer;      // Timer used for pairing
	interface Timer<TMilli> as Milli10Timer;
	interface Timer<TMilli> as Milli60Timer;    // Timer used for MISSING alert

	// interface used to perform sensor reading
	interface Read<pos_t> as PositionRead;
    interface Read<kinematic_status_t> as KineticRead;
  }

} implementation {
	
	uint8_t role; 
  	char key[21] = "j2GV2SEI81x2CHxYNWSf"; // KEYS[0];
  	
  	message_t packet;
  	am_addr_t pair_addr = AM_BROADCAST_ADDR;
  	bool locked = FALSE;

  	nx_uint16_t x;
  	nx_uint16_t y;
  	nx_uint8_t kinematic_status;

  	//pairing, operation
  	nx_uint8_t mode;


  	//***************** Boot interface ********************//
  	event void Boot.booted() {
		dbg("boot","Application booted.\n");
		call SplitControl.start();
  	}

  	//***************** SplitControl interface ********************//
  	event void SplitControl.startDone(error_t err){
  		// 10 second timer to send messages 
  		if ( TOS_NODE_ID % 2 == 0 ) {
  			role = PARENT; 
  		} else {
  			role = CHILD; 
  		}
    	
    	call MilliTimer.startPeriodic(PAIRING_TIME); 
  	}

  	event void SplitControl.stopDone(error_t err){
    	/* Fill it ... */
  	}
  
  	void send_packet(am_addr_t dest, uint8_t type, uint16_t pos_x, uint16_t pos_y, uint8_t kin_status) {
  		my_msg_t* msg;

        if (locked) {
            dbg("radio", "Radio locked. Skipping signaling packet. \n");
            return;
        }
        
        msg = (my_msg_t*) call Packet.getPayload(&packet, sizeof(my_msg_t));
        if (msg == NULL) return;

       	// msg->key = strncpy(msg->key, key, 21);
	    msg->msg_type = type;
	    msg->x = pos_x; 
		msg->y = pos_y; 
		msg->kinematic_status = kin_status; 
	    
	    if( call AMSend.send(dest, &packet, sizeof(my_msg_t)) == SUCCESS ){
		   	dbg("radio", 
		   	    "packet sent: {\n\tsnd=%u->rcv=%u\n\tkey=%s\n\ttype=%u\n\tpos=(%u, %u)\n\tkinematic status=%u\n}.\n", 
		   	    call SendPacket.source(&packet), call SendPacket.destination(&packet), msg->key, msg->msg_type, msg->x, msg->y, msg->kinematic_status);
            
            locked = TRUE;
            dbg("radio", "radio locked.\n");
        }
  	}

  	//***************** MilliTimer interface ********************//
  	event void MilliTimer.fired() {
        send_packet(AM_BROADCAST_ADDR, PAIRING, 0, 0, 0); 
  	}

  	event void Milli10Timer.fired() {
		call KineticRead.read(); 
		call PositionRead.read(); 
  	}

  	event void Milli60Timer.fired() {

  	}


  	//********************* AMSend interface ****************//
  	event void AMSend.sendDone(message_t* buf,error_t err) {
  		locked = FALSE; 
  		
		if ( err != SUCCESS ) return; 
		
		dbg("radio", "Packet sent successfully. \n"); 
  	}
  	
  	void handle_pairing(my_msg_t* received, message_t* rcv, bool answer) {
  	
  		if ( pair_addr != AM_BROADCAST_ADDR ) return; 
  		
  		pair_addr = call ReceivePacket.source(rcv); 
  		dbg("control", "PAIRING WITH: %u\n", pair_addr);  		
  		
  		if ( answer ) {
  			send_packet(pair_addr, PAIREND, 0, 0, 0); 
  		}
  	
  	}

  	//***************************** Receive interface *****************//
  	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
  		my_msg_t* msg = (my_msg_t*) payload; 
  		
  		dbg("radio", 
  		    "Packet received: {\n\tsnd=%u->rcv=%u\n\tkey=%s\n\ttype=%u\n\tpos=(%u, %u)\n\tkinematic status=%u}.\n", 
  			call ReceivePacket.source(buf), call ReceivePacket.destination(buf), msg->key, msg->msg_type, msg->x, msg->y, msg->kinematic_status);
  		
  		if ( msg->msg_type == PAIRING ) {
  			handle_pairing(msg, buf, TRUE); 
  		} else if ( msg->msg_type == PAIREND ) {
  			handle_pairing(msg, buf, FALSE); 
  		}
  	
		return buf;

  	}

    //************************* Read interface **********************//
    event void KineticRead.readDone(error_t result, kinematic_status_t data) {
        dbg("app_kin_sensor", "KINEMATIC STATUS: %d\n", data);
    }

    event void PositionRead.readDone(error_t result, pos_t data) {
        dbg("app_kin_sensor", "POSITION: (x=%u, y=%u)\n", data.x, data.y);
    }

}
