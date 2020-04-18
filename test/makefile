CFLAGS+= -lpthread ../libelf/lib/libelf.a -static

ifeq ($(findstring arm, $(TARGET)), arm)
	PIE_ENCODER = ../pie/pie-arm-encoder.o ../pie/pie-thumb-encoder.o
	PIE_DECODER = ../pie/pie-arm-decoder.o ../pie/pie-thumb-decoder.o
	CFLAGS+=-march=armv7-a -mfpu=neon
else ifeq ($(TARGET),aarch64)
	PIE_ENCODER = ../pie/pie-a64-encoder.o
	PIE_DECODER = ../pie/pie-a64-decoder.o
endif

ifndef IS_NATIVE
	CFLAGS+=libelf/lib/libelf.a
else
	CFLAGS+= -DIS_NATIVE -lelf
endif

.PHONY: clean

all: self_modifying signals load_store

self_modifying: $(PIE_ENCODER) self_modifying.c
	$(CC) $(CFLAGS) $^ -lpthread -o $@.elf

signals: $(PIE_ENCODER) signals.c signals.S
	$(CC) $(CFLAGS) $^ -lpthread -o $@.elf

load_store: $(PIE_ENCODER) $(PIE_DECODER) load_store.c load_store.S
	$(CC) -g $(CFLAGS) $^ -lpthread -o $@.elf

clean:
	rm -f *.elf
