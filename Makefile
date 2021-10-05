COMPONENT = projectAppC
CFLAGS += -I$(TOSDIR)/lib/printf
#in order to speed up the printf function we reduced the buffer size
CFLAGS += -DPRINTF_BUFFER_SIZE=100 
include $(MAKERULES)