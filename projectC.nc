#include "Timer.h"
#include "project.h"
#include "printf.h"	

#define MAX_MOTES 8

module projectC @safe() {
	uses {
    	interface Boot;
    	interface Receive;
    	interface AMSend; 
		interface Timer<TMilli> as MilliTimer;
	 	interface SplitControl as AMControl;
    	interface Packet;
	}
}

implementation {

	message_t packet;
	
	uint16_t periodic_timer = 500;
	uint16_t counter = 1;
	bool locked;
	uint16_t last_count[MAX_MOTES]; 
	uint8_t streak[MAX_MOTES]; //uint8_t save memory, will just go up to 10
	
	
	event void Boot.booted() {
		call AMControl.start();
	}
	
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			printf("RADIO TURNED ON\n");
			call MilliTimer.startPeriodic(periodic_timer); //start timer
		}
		else { //otherwise try to start the radio again and again
      		printf("RADIO FAILED TO START, RETRING...\n");
      		call AMControl.start();
    	}
	}
	
	event void AMControl.stopDone(error_t err) {
		//do nothing
	}
	
	event void MilliTimer.fired() {
		if (locked) {
      		return;
   	    }
   	    else {
   	    	
   	    	prox_msg_t* proxm = (prox_msg_t*)call Packet.getPayload(&packet, sizeof(prox_msg_t));
   	    	if (proxm == NULL){ return;}
   	    	
   	    	//populating the message
   	    	proxm->senderId = TOS_NODE_ID;
   	    	proxm->counter = counter; 
   	    	  	    	
   	    	if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(prox_msg_t)) == SUCCESS){  
   	    	    counter ++;    		
   	    		locked = TRUE;
   	    		//printf("SENT BROADCAST MESSAGE\n");
   	    	}
   	    
   		}
   	}
	
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
		
		if (len != sizeof(prox_msg_t)) {return bufPtr;}
		else {
			prox_msg_t* proxm = (prox_msg_t*)payload;
			
			//closeness tracking logic
			if (proxm->counter == last_count[proxm->senderId-1] + 1 || (last_count[proxm->senderId-1] == 65535 && proxm->counter == 0)){
				streak[proxm->senderId-1] ++;
				printf("Consecutive message recived from mote %u, streak is %u\n", proxm->senderId, streak[proxm->senderId-1]);	
			}else{
				streak[proxm->senderId-1] = 1;
				last_count[proxm->senderId-1] = 0;
				printf("Non consecutive message recived from mote %u, streak resetted\n", proxm->senderId);
			}

			if(streak[proxm->senderId-1] == 10){
				printf("Recived 10 consecutive messages from mote %u, SENDING ALLERT!\n", proxm->senderId);
				printf("%u %u\n", TOS_NODE_ID, proxm->senderId);
				streak[proxm->senderId-1] = 0;
			}

			last_count[proxm->senderId-1] = proxm->counter;
			return bufPtr;
			
		}
	}

	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    	if (&packet == bufPtr) {
      		locked = FALSE; 
    	}
  	}
	
}
