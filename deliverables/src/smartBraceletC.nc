#include "TestSerial.h"
#include "smartBracelet.h"
#include "Timer.h"
#include "string.h"

#define PAIRING_TIME 300
#define KEEP_ALIVE_TIME 15000
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

	// interfaces for serial port
	interface AMSend as SerialSend;
	interface Packet as SerialPacket;
	interface SplitControl as SerialSC;

	// interface for timer
	interface Timer<TMilli> as MilliTimer;      // Timer used for pairing
	interface Timer<TMilli> as Milli10Timer;
	interface Timer<TMilli> as Milli60Timer;    // Timer used for MISSING alert
    interface Timer<TMilli> as KeepAliveTimer;

	// interface used to perform sensor reading
    interface Read<sensor_data_t> as SensorRead;
  }

} implementation {

	uint8_t role;
  	nx_uint8_t key[21];

  	message_t packet;
  	am_addr_t pair_addr = AM_BROADCAST_ADDR;
  	bool locked = FALSE;

  	message_t serial_packet;
  	bool serial_locked = FALSE;

  	nx_uint16_t x;
  	nx_uint16_t y;
  	nx_uint8_t kinematic_status;

  	//pairing, operation
  	nx_uint8_t mode;
  	//used to terminate pairing, if pairend is sent and received
  	nx_uint8_t confirmation;
  	bool ack_received; 
  	bool pairend_received; 
  	
  	uint8_t keep_alive_counter; 

  	void nx_strncpy(nx_uint8_t* dst, const char* src, int n) {
  		int i;

  		for (i=0; i<n; i++) {
  			dst[i] = src[i];
  		}
  	}

  	void nx_intncpy(nx_uint8_t* dst, nx_uint8_t* src, int n) {
  		int i;

  		for (i=0; i<n; i++) {
  			dst[i] = src[i];
  		}
  	}

  	int nx_strncmp(nx_uint8_t* s1, nx_uint8_t* s2, int n) {
  		int i;

  		for (i=0; i<n; i++) {
  			if (s1[i] > s2[i]) return -1;
  			if (s1[i] < s2[i]) return 1;
  		}

  		return 0;
  	}

    void send_serial_packet(nx_uint8_t type, nx_uint16_t alert_x, nx_uint16_t alert_y) {
  		test_serial_msg_t* msg;

  		if ( serial_locked ) return;

  		msg = (test_serial_msg_t*) call SerialPacket.getPayload(&serial_packet, sizeof(test_serial_msg_t));
  		if (msg == NULL) return;

  		msg->alert_type = type;
  		msg->x = alert_x;
  		msg->y = alert_y;
		// msg->counter = x;

  		if ( call SerialSend.send(AM_BROADCAST_ADDR, &serial_packet, sizeof(test_serial_msg_t)) == SUCCESS ) {
  			dbg("serial", "serial packet sent: {\n\ttype=%u\n\tlast_pos=(x=%u, y=%u)\n}\n", type, x, y);
  			serial_locked = TRUE;
  		}
  	}


  	//***************** Boot interface ********************//
  	event void Boot.booted() {
		call SplitControl.start();
		call SerialSC.start();

		nx_strncpy(key, KEYS[(TOS_NODE_ID - 1)/2], 20);
		dbg("boot","Application booted with key %s.\n", key);
  	}


  	//***************** SplitControl interface ********************//
  	char* mode_string(uint8_t m) {
  		if (m == BROADCASTING_STATE) return "BROADCASTING_STATE"; 
  		if (m == PAIRING_STATE) return "PAIRING_STATE"; 
  		if (m == OPERATION_STATE) return "OPERATION_STATE"; 
  		return ""; 
  	}
  	
  	event void SplitControl.startDone(error_t err){
  		// 10 second timer to send messages
  		if ( TOS_NODE_ID % 2 == 0 ) {
  			role = PARENT;
  		} else {
  			role = CHILD;
  		}

    	if(err == SUCCESS){
    		dbg("control", "starting MilliTimer.\n"); 
    	  	mode = BROADCASTING_STATE;
  			confirmation = 0;
  			ack_received = FALSE; 
  			pairend_received = FALSE; 
  			keep_alive_counter = 0; 
  			pair_addr = AM_BROADCAST_ADDR; 
    		call MilliTimer.startPeriodic(PAIRING_TIME);	//start pairing
    	}
  		else call SplitControl.start();
  	}

  	event void SplitControl.stopDone(error_t err){
    	call SplitControl.start();
  	}


  	event void SerialSC.startDone(error_t err) {
  		if ( err == SUCCESS ) {
  			dbg("serial", "Serial bus active. \n");
  			// send_serial_packet(3, 0, 0);
  		} else {
  			dbg("serial", "Failed to activate the serial bus. Trying again. \n");
  			call SerialSC.start();
  		}

  	}

  	event void SerialSC.stopDone(error_t err) {
        call SerialSC.start();
    }

  	char* kinematic_string(uint8_t kinematic){
  		if(kinematic == STANDING) return "STANDING";
  		else if(kinematic == WALKING) return "WALKING";
  		else if(kinematic == RUNNING) return "RUNNING";
  		else return "FALLING";
  	}
  	
  	char* msg_type_string(uint8_t msg_type) {
  		if (msg_type == PAIRING) return "PAIRING"; 
  		if (msg_type == PAIREND) return "PAIREND"; 
  		if (msg_type == INFO) return "INFO"; 
  		return "KEEPALIVE"; 
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
		nx_intncpy(msg->key, key, 20);
		call Acks.requestAck(&packet);
	    if( call AMSend.send(dest, &packet, sizeof(my_msg_t)) == SUCCESS ){
		   	dbg("radio",
		   	    "packet sent: {\n\tsnd=%u->rcv=%u\n\tkey=%s\n\ttype=%s\n\tpos=(%u, %u)\n\tkinematic status=%s\n}.\n",
		   	    call SendPacket.source(&packet), call SendPacket.destination(&packet), msg->key, msg_type_string(msg->msg_type), msg->x, msg->y, kinematic_string(msg->kinematic_status));

            locked = TRUE;
            dbg("radio", "radio locked.\n");
        }
  	}


  	//***************** MilliTimer interface ********************//
  	void reset() {
        call SplitControl.stop();
        call SerialSC.stop();
    }
    
  	event void MilliTimer.fired() {
        send_packet(AM_BROADCAST_ADDR, PAIRING, 0, 0, 0);
  	}

  	event void Milli10Timer.fired() {
  		dbg("control","Child timer fired\n");
		call SensorRead.read();
  	}

  	event void Milli60Timer.fired() {
		dbg("alert", "MISSING ALERT! LAST KNOWN POSITION: x=%u,y=%u,kinematic_status=%s\n", x,y,kinematic_string(kinematic_status));
		send_serial_packet(2, x, y);

		mode = PAIRING;

        reset();

  	}

    event void KeepAliveTimer.fired() {
        if (role == PARENT) {
        	dbg("control", "PARENT keepAlive timer fired, sending KEEP_ALIVE packet.\n"); 
            send_packet(pair_addr, KEEP_ALIVE, 0, 0, 0);
            return;
        }

        if (role == CHILD) {
        	dbg("control", "CHILD keepAlive timer fired, resetting. \n"); 
            reset();
            return;
        }
    }


  	//********************* AMSend interface ****************//
  	void isPairingDone(nx_uint8_t conf){
  		if(ack_received && pairend_received){
  			dbg("control", "Ending Pairing phase, going into Operation mode\n");
  			mode = OPERATION_STATE;
  			if(role == PARENT){
  				call Milli60Timer.startOneShot(60000u);
                // the parent sends messages with higher frequency to consider
                // network delays 
                call KeepAliveTimer.startPeriodic(KEEP_ALIVE_TIME - 3000);
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

		if(mode == PAIRING_STATE && call Acks.wasAcked(buf)){
			confirmation++;
			ack_received = TRUE; 
			dbg("control", "Ack for PAIREND send received, count: %u\n", confirmation);
			isPairingDone(confirmation);
		}
		else if(mode == PAIRING_STATE){
			dbg("control", "Confirmation for PAIREND resent, Ack was not received\n");
			send_packet(pair_addr, PAIREND, 0, 0, 0);
		}
  	}


  	void handle_pairing(my_msg_t* received, message_t* rcv, bool is_pairing) {
        // if we receive the first PAIRING MESSAGE (the pair_addr hasn't been
        // modified), we save the sender message only if it has our key.
  		if (is_pairing && pair_addr == AM_BROADCAST_ADDR) {
  			if(nx_strncmp(key, received->key, 20) == 0){
	  			pair_addr = call ReceivePacket.source(rcv);
	  			dbg("control", "PAIRING WITH: %u\n", pair_addr);
	  			//dbg("control", "Confirmation for PAIREND sent, count: %u+1\n", confirmation);
	  			mode = PAIRING_STATE;
	  			send_packet(pair_addr, PAIREND, 0, 0, 0);
	  		}
  		}
  		else if( !is_pairing && pair_addr != TOS_NODE_ID ){
  			confirmation++;
  			pairend_received = TRUE; 
  			dbg("control", "PAIREND received, count: %u\n", confirmation);
  			isPairingDone(confirmation);
  		}

  	}

  	void handle_info(my_msg_t* received){
  		x = received->x;
  		y = received->y;
  		kinematic_status = received->kinematic_status;

        if (kinematic_status == FALLING && role == PARENT) {
            dbg("alert", "ALERT. FALLING status detected. Baby is in position (x=%u, y=%u)\n", x, y);
            send_serial_packet(1, x, y);
        }
  	}

    void handle_rcv_pairing(my_msg_t* msg, message_t* buf) { 
       	handle_pairing(msg, buf, TRUE);
    }
    
    void handle_rcv_pairend(my_msg_t* msg, message_t* buf) {
       	dbg("control", "Received Pairing Confirmation from other side\n");
        handle_pairing(msg, buf, FALSE);
        call MilliTimer.stop();
    }

    void handle_rcv_operational(my_msg_t* msg, message_t* buf) {
        if (role == CHILD) {
            if (msg->msg_type == KEEP_ALIVE) {
                call KeepAliveTimer.startOneShot(KEEP_ALIVE_TIME);
            }
        }

        // used to confirm we are both in info mode and msg comes from child addr
        if (call ReceivePacket.source(buf) == pair_addr) {
            dbg("control", "Received Info from Child\n");
            handle_info(msg);
            call Milli60Timer.startOneShot(60000u);
        }
    }

    event void SerialSend.sendDone(message_t* buf,error_t err) {
  		serial_locked = FALSE;

  		if ( err == SUCCESS ) {
  			dbg("serial", "Message successfully delivered on serial bus. \n");
  		}
  	}

  	//***************************** Receive interface *****************//
  	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
  		my_msg_t* msg = (my_msg_t*) payload;
  		

  		//dbg("radio",
  		//    "Packet received: {\n\tsnd=%u->rcv=%u\n\tkey=%s\n\ttype=%u\n\tpos=(%u, %u)\n\tkinematic status=%s\n}.\n",
  		//	call ReceivePacket.source(buf), call ReceivePacket.destination(buf), msg->key, msg->msg_type, msg->x, msg->y, kinematic_string(msg->kinematic_status));

  		if ( msg->msg_type == PAIRING ) {
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
  			call Milli60Timer.startOneShot(60000u);
  		}
		dbg("radio",
  		    "Packet received (mode=%s): {\n\tsnd=%u->rcv=%u\n\tkey=%s\n\ttype=%s\n\tpos=(%u, %u)\n\tkinematic status=%s\n}.\n", mode_string(mode), 
  			call ReceivePacket.source(buf), call ReceivePacket.destination(buf), msg->key, msg_type_string(msg->msg_type), msg->x, msg->y, kinematic_string(msg->kinematic_status));
		
		if (msg->msg_type == PAIRING) handle_rcv_pairing(msg, buf); 
	
        if (msg->msg_type == PAIREND) handle_rcv_pairend(msg, buf);
        
        if (msg->msg_type == INFO) handle_rcv_operational(msg, buf); 


		return buf;
  	}

    //************************* Read interface **********************//
    event void SensorRead.readDone(error_t result, sensor_data_t data) {
    	if (role != CHILD || mode != OPERATION_STATE) return;

    	if (result != SUCCESS) {
    		dbg("app_sensor", "Error in reading sensor data. \n");
    		return;
    	}

    	dbg("app_sensor", "Data received from sensor: {\n\tkinetic_status=%u\n\tposition=(x=%u, y=%u)\n}\n", data.kinematic_status, data.x, data.y);
    	send_packet(pair_addr, INFO, data.x, data.y, data.kinematic_status);
    }

}
