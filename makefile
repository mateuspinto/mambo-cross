ifndef TARGET
	TARGET=aarch64
endif

#PLUGINS+=plugins/branch_count.c
#PLUGINS+=plugins/soft_div.c
#PLUGINS+=plugins/tb_count.c
#PLUGINS+=plugins/mtrace.c plugins/mtrace.S
#PLUGINS+=plugins/cachesim/cachesim.c plugins/cachesim/cachesim.S plugins/cachesim/cachesim_model.c
#PLUGINS+=plugins/poc_log_returns.c
#PLUGINS+=plugins/instruction_mix.c
#PLUGINS+=plugins/strace.c

OPTS= -DDBM_LINK_UNCOND_IMM
OPTS+=-DDBM_INLINE_UNCOND_IMM
OPTS+=-DDBM_LINK_COND_IMM
OPTS+=-DDBM_LINK_CBZ
OPTS+=-DDBM_LINK_TBZ
OPTS+=-DDBM_TB_DIRECT #-DFAST_BT
OPTS+=-DLINK_BX_ALT
OPTS+=-DDBM_INLINE_HASH
OPTS+=-DDBM_TRACES #-DTB_AS_TRACE_HEAD #-DBLXI_AS_TRACE_HEAD
#OPTS+=-DCC_HUGETLB -DMETADATA_HUGETLB

CFLAGS+=-D_GNU_SOURCE -std=gnu99 -O2 

LDFLAGS+=-static -ldl -Wl,-Ttext-segment=$(or $(TEXT_SEGMENT),0xa8000000)
LIBS=-lpthread 
HEADERS=*.h makefile
INCLUDES=-I/usr/include/libelf
SOURCES= dispatcher.S common.c dbm.c traces.c syscalls.c dispatcher.c signals.c util.S
SOURCES+=api/helpers.c api/plugin_support.c api/branch_decoder_support.c api/load_store.c
SOURCES+=elf_loader/elf_loader.o

# Defining MAMBO Flags
ifeq ($(findstring arm, $(TARGET)), arm)
	CFLAGS += -march=armv7-a -mfpu=neon 
	HEADERS += api/emit_arm.h api/emit_thumb.h
	PIE = pie/pie-arm-encoder.o pie/pie-arm-decoder.o pie/pie-arm-field-decoder.o
	PIE += pie/pie-thumb-encoder.o pie/pie-thumb-decoder.o pie/pie-thumb-field-decoder.o
	SOURCES += scanner_thumb.c scanner_arm.c
	SOURCES += api/emit_arm.c api/emit_thumb.c
	NATIVE_TARGETS = arm thumb

	ifndef IS_NATIVE
		CROSS_COMPILER=arm-linux-gnu-
		LIBS+=libelf/lib/libelf.a
	else
		LIBS+=-lelf
		CFLAGS+= -DIS_NATIVE
	endif

else ifeq ($(TARGET),aarch64)
	HEADERS += api/emit_a64.h
	PIE += pie/pie-a64-field-decoder.o pie/pie-a64-encoder.o pie/pie-a64-decoder.o
	SOURCES += scanner_a64.c
	SOURCES += api/emit_a64.c
	NATIVE_TARGETS = a64

	ifndef IS_NATIVE
		CROSS_COMPILER=aarch64-linux-gnu-
		LIBS+=libelf/lib/libelf.a
	else
		LIBS+=-lelf
		CFLAGS+= -DIS_NATIVE
	endif

endif

CC=$(CROSS_COMPILER)gcc

export CC
export NATIVE_TARGETS
export TARGET
export IS_NATIVE

ifdef PLUGINS
	CFLAGS += -DPLUGINS_NEW 
endif

.PHONY: pie libelf clean cleanall test

all:
	$(info MAMBO: target architecture "$(TARGET)". Using cross-compile "$(CROSS_COMPILER)".)
	@$(MAKE) --no-print-directory pie && $(MAKE) --no-print-directory libelf && $(MAKE) --no-print-directory dbm

pie:
	@$(MAKE) --no-print-directory -C pie/ native

libelf:
	@$(MAKE) --no-print-directory -C libelf/

%.o: %.c %.h
	$(CC) $(CFLAGS) -c -o $@ $<

dbm: $(HEADERS) $(SOURCES) $(PLUGINS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(OPTS) $(INCLUDES) -o $@.elf $(SOURCES) $(PLUGINS) $(PIE) $(LIBS) $(PLUGIN_ARGS)

clean:
	rm -f dbm.elf elf_loader/elf_loader.o

cleanall:
	@$(MAKE) --no-print-directory clean && $(MAKE) --no-print-directory -C pie/ clean && $(MAKE) --no-print-directory -C libelf/ clean && $(MAKE) --no-print-directory -C test/ clean

api/emit_%.c: pie/pie-%-encoder.c api/generate_emit_wrapper.rb
	ruby api/generate_emit_wrapper.rb $< > $@

api/emit_%.h: pie/pie-%-encoder.c api/generate_emit_wrapper.rb
	ruby api/generate_emit_wrapper.rb $< header > $@

test:
	@$(MAKE) --no-print-directory all && $(MAKE) --no-print-directory -C test/