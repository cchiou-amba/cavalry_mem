#
# Makefile for libcavalry_mem
#
# Copyright (C) 2026, Ambarella International LLC
#

CROSS_COMPILE ?= aarch64-linux-gnu-
CC = $(CROSS_COMPILE)gcc
AR = $(CROSS_COMPILE)ar

CFLAGS ?= -O2 -Wall -fPIC -fvisibility=hidden -DAMBA_AMYOC_BUILD -DAMBA_SOC_N1_655
CFLAGS += -Iinc -Isrc -I../../linux/amba-cavalry/include -I../../../drivers/cavalry/include/cavalry_v3

LDFLAGS ?= -shared -lpthread

SRCS = src/cavalry_mem.c
OBJS = $(SRCS:.c=.o)

LIB_SO = libcavalry_mem.so
LIB_A = libcavalry_mem.a

all: $(LIB_SO) $(LIB_A)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(LIB_SO): $(OBJS)
	$(CC) -shared -Wl,-soname,$@.3 -o $@ $^ $(LDFLAGS)

$(LIB_A): $(OBJS)
	$(AR) rcs $@ $^

clean:
	rm -f $(OBJS) $(LIB_SO) $(LIB_A)

.PHONY: all clean
