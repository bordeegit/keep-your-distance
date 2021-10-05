#ifndef PROJECT_H
#define PROJECT_H 

typedef nx_struct prox_msg{
	nx_uint16_t counter;
	nx_uint8_t senderId;
}  prox_msg_t;

enum { 
  AM_RADIO_COUNT_MSG = 6,
};

#endif
