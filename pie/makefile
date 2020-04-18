CC=gcc
CFLAGS= -Os -Wall -std=c99 #-DPIE_AUTOINC

ifeq ($(findstring arm, $(TARGET_ARCH)), arm)
	NATIVE_TARGETS = arm thumb

	
	ifeq ($(IS_NATIVE),0)
		CROSS_COMPILER=arm-linux-gnu-
		CFLAGS+= -static -g 
	else
		CROSS_COMPILER=
		CFLAGS+=-mcpu=native 
	endif

endif
ifeq ($(TARGET_ARCH),aarch64)
	NATIVE_TARGETS = a64
	
	ifeq ($(IS_NATIVE),0)
		CROSS_COMPILER=aarch64-linux-gnu-
		CFLAGS+= -static -g 
	else
		CROSS_COMPILER=
		CFLAGS+=-mcpu=native 
	endif

endif

.SECONDARY:
.PHONY: native print_arch all pie clean

native: print_arch $(NATIVE_TARGETS)
	
print_arch:
	$(info PIE: target architecture "$(TARGET_ARCH)")

all: thumb arm a64

%:
	$(MAKE) --no-print-directory ARCH=$@ pie

pie: pie-$(ARCH)-decoder.o pie-$(ARCH)-encoder.o pie-$(ARCH)-field-decoder.o

pie-$(ARCH)-%.o: pie-$(ARCH)-%.c pie-$(ARCH)-%.h
	$(CROSS_COMPILER)$(CC) -c $(CFLAGS) $< -o $@

pie-$(ARCH)-%.h: generate_%.rb $(ARCH).txt
	ruby $< $(ARCH) header > $@

pie-$(ARCH)-%.c: generate_%.rb $(ARCH).txt
	ruby $< $(ARCH) > $@

clean:
	rm -f *.o pie-arm-*.h pie-thumb-*.h pie-a64-*.h pie-*.c

