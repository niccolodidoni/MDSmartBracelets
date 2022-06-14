#include "smartBracelet.h"
#include "Timer.h"
#include "string.h"

#define PAIRING_TIME 300
#define BOTHWAYS 2

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
	interface PacketAcknowledgements as Acks;

	// interface for timer
	interface Timer<TMilli> as MilliTimer;      // Timer used for pairing
	interface Timer<TMilli> as Milli10Timer;
	interface Timer<TMilli> as Milli60Timer;    // Timer used for MISSING alert

	// interface used to perform sensor reading
	interface Read<pos_t> as PositionRead;
    interface Read<kinematic_status_t> as KineticRead;
    interface Read<sensor_data_t> as SensorRead;
  }

} implementation {

	uint8_t role;
  	nx_uint8_t key[21];

  	message_t packet;
  	am_addr_t pair_addr = AM_BROADCAST_ADDR;
  	bool locked = FALSE;

  	nx_uint16_t x;
  	nx_uint16_t y;
  	nx_uint8_t kinematic_status;

  	//pairing, operation
  	nx_uint8_t mode;
  	//used to terminate pairing, if pairend is sent and received
  	nx_uint8_t confirmation;


  	//***************** Boot interface ********************//
  	event void Boot.booted() {
		call SplitControl.start();

		strcpy(key, KEYS[(TOS_NODE_ID - 1) / 2]);
		dbg("boot","Application booted with key %s.\n", key);
  	}

  	//***************** SplitControl interface ********************//
  	event void SplitControl.startDone(error_t err){
  		// 10 second timer to send messages
  		if ( TOS_NODE_ID % 2 == 0 ) {
  			role = PARENT;
  		} else {
  			role = CHILD;
  		}


    	if(err == SUCCESS){
    	  	mode = PAIRING;
  			confirmation = 0;
    		call MilliTimer.startPeriodic(PAIRING_TIME);	//start pairing
    	}
  		else call SplitControl.start();
  	}

  	event void SplitControl.stopDone(error_t err){
    	/* Fill it ... */
  	}
  	
  	char* kinematic_string(uint8_t kinematic){
  		if(kinematic == 0) return "STANDING";
  		else if(kinematic == 1) return "WALKING";
  		else if(kinematic == 2) return "RUNNING";
  		else return "FALLING";
  	
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
		strcpy(msg->key, key);
		call Acks.requestAck(&packet);
	    if( call AMSend.send(dest, &packet, sizeof(my_msg_t)) == SUCCESS ){
		   	dbg("radio",
		   	    "packet sent: {\n\tsnd=%u->rcv=%u\n\tkey=%s\n\ttype=%u\n\tpos=(%u, %u)\n\tkinematic status=%s\n}.\n",
		   	    call SendPacket.source(&packet), call SendPacket.destination(&packet), msg->key, msg->msg_type, msg->x, msg->y, kinematic_string(msg->kinematic_status));

            locked = TRUE;
            dbg("radio", "radio locked.\n");
        }
  	}

  	//***************** MilliTimer interface ********************//
  	event void MilliTimer.fired() {
        send_packet(AM_BROADCAST_ADDR, PAIRING, 0, 0, 0);
  	}

  	event void Milli10Timer.fired() {
  		dbg("control","Child timer fired\n");
		// call KineticRead.read();
		// call PositionRead.read();
		call SensorRead.read(); 
  	}

  	event void Milli60Timer.fired() {
		dbg("alert", "MISSING ALERT! LAST KNOWN POSITION: x=%u,y=%u,kinematic_status=%s\n", x,y,kinematic_string(kinematic_status));
  	}
  	
  	void isPairingDone(nx_uint8_t conf){
  		if(conf == BOTHWAYS){
  			dbg("control", "Ending Pairing phase, going into Operation mode\n");
  			mode = INFO;
  			if(role == PARENT){
  				call Milli60Timer.startOneShot(60000);
  			}
  			else if(role == CHILD) {
  				call Milli10Timer.startPeriodic(10000);
  			}
  		}
  	}


  	//********************* AMSend interface ****************//
  	event void AMSend.sendDone(message_t* buf,error_t err) {
  		locked = FALSE;

		if ( err != SUCCESS ) return;

		dbg("radio", "Packet sent successfully. \n");
		
		if(mode == PAIREND && call Acks.wasAcked(buf)){
			confirmation++;
			dbg("control", "Ack for PAIREND send received, count: %u\n", confirmation);
			isPairingDone(confirmation);
		}
		else if(mode == PAIREND){
			dbg("control", "Confirmation for PAIREND resent, Ack was not received\n");
			send_packet(pair_addr, PAIREND, 0, 0, 0);
		}
  	}


  	void handle_pairing(my_msg_t* received, message_t* rcv, bool is_pairing) {

        // if we receive the first PAIRING MESSAGE (the pair_addr hasn't been
        // modified), we save the sender message only if it has our key.
  		if (is_pairing && pair_addr == AM_BROADCAST_ADDR) {
  			if(strcmp(key, received->key) == 0){
	  			pair_addr = call ReceivePacket.source(rcv);
	  			dbg("control", "PAIRING WITH: %u\n", pair_addr);
	  			//dbg("control", "Confirmation for PAIREND sent, count: %u+1\n", confirmation);
	  			mode = PAIREND;
	  			send_packet(pair_addr, PAIREND, 0, 0, 0);
	  		}
  		}
  		else if( !is_pairing && pair_addr != TOS_NODE_ID){
  			confirmation++;
  			dbg("control", "Confirmation for PAIREND received, count: %u\n", confirmation);
  			isPairingDone(confirmation);
  		}

  	}

  	void handle_info(my_msg_t* received){
  		x = received->x;
  		y = received->y;
  		kinematic_status = received->kinematic_status;

        if (kinematic_status == FALLING) {
            dbg("alert", "ALERT. FALLING status detected. Baby is in position (x=%u, y=%u)", x, y); 
        }
  	}


  	//***************************** Receive interface *****************//
  	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
  		my_msg_t* msg = (my_msg_t*) payload;

  		dbg("radio",
  		    "Packet received: {\n\tsnd=%u->rcv=%u\n\tkey=%s\n\ttype=%u\n\tpos=(%u, %u)\n\tkinematic status=%s\n}.\n",
  			call ReceivePacket.source(buf), call ReceivePacket.destination(buf), msg->key, msg->msg_type, msg->x, msg->y, kinematic_string(msg->kinematic_status));

  		if ( msg->msg_type == PAIRING) {
  			handle_pairing(msg, buf, TRUE);
  		} else if ( msg->msg_type == PAIREND ) {
  			dbg("control", "Received Pairing Confirmation from other side\n");
  			handle_pairing(msg, buf, FALSE);
  			call MilliTimer.stop();
  		}
  		// used to confirm we are both in info mode and msg comes from child addr
  		else if ( msg->msg_type == INFO && mode == INFO && call ReceivePacket.source(buf) == pair_addr) {	
  			dbg("control", "Received Info from Child\n");
  			handle_info(msg);
  			call Milli60Timer.startOneShot(60000);
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
    
    event void SensorRead.readDone(error_t result, sensor_data_t data) {
    	if (role != CHILD) return; 
    
    	if (result != SUCCESS) {
    		dbg("app_sensor", "Error in reading sensor data. \n"); 
    		return; 
    	}
    	
    	dbg("app_sensor", "Data received from sensor: {\n\tkinetic_status=%u\n\tposition=(x=%u, y=%u)\n}\n", data.kinematic_status, data.x, data.y); 
    	send_packet(pair_addr, INFO, data.x, data.y, data.kinematic_status); 
    }

}
