ifeq ($(findstring arm, $(TARGET)), arm)
	PIE_ENCODER = ../pie/pie-arm-encoder.o ../pie/pie-thumb-encoder.o
	PIE_DECODER = ../pie/pie-arm-decoder.o ../pie/pie-thumb-decoder.o
	CFLAGS+=-march=armv7-a -mfpu=neon
else ifeq ($(TARGET),aarch64)
	PIE_ENCODER = ../pie/pie-a64-encoder.o
	PIE_DECODER = ../pie/pie-a64-decoder.o
endif

CFLAGS+= -lpthread ../libelf/lib/libelf.a -static

.PHONY: clean

portable: mmap_munmap mprotect_exec self_modifying signals load_store

aarch32: portable hw_div

aarch64: portable

hw_div: hw_div.S
	$(CC) -mcpu=cortex-a15 $< $(LDFLAGS) -o $@

self_modifying: $(PIE_ENCODER) self_modifying.c
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -lpthread -o $@

signals: $(PIE_ENCODER) signals.c signals.S
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -lpthread -o $@

load_store: $(PIE_ENCODER) $(PIE_DECODER) load_store.c load_store.S
	$(CC) -g $(CFLAGS) $^ $(LDFLAGS) -lpthread -o $@

clean:
	rm -f mmap_munmap mprotect_exec self_modifying signals hw_div load_store
