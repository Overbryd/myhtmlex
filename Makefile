MIX = mix
MYHTMLEX_CFLAGS = -g -O2 -std=c99 -pedantic -Wcomment -Wall
# we need to compile position independent code
MYHTMLEX_CFLAGS += -fpic -DPIC
# For some reason __erl_errno is undefined unless _REENTRANT is defined
MYHTMLEX_CFLAGS += -D_REENTRANT
# myhtmlex is using stpcpy, as defined in gnu string.h
# MYHTMLEX_CFLAGS += -D_GNU_SOURCE
# base on the same posix c source as myhtml
# MYHTMLEX_CFLAGS += -D_POSIX_C_SOURCE=199309
# turn warnings into errors
# MYHTMLEX_CFLAGS += -Werror
# ignore unused variables
# MYHTMLEX_CFLAGS += -Wno-unused-variable
# ignore unused parameter warnings
MYHTMLEX_CFLAGS += -Wno-unused-parameter

# set erlang include path
ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version)])])' -s init stop -noshell)
MYHTMLEX_CFLAGS += -I$(ERLANG_PATH)/include

# expecting myhtml as a submodule in c_src/
# that way we can pin a version and package the whole thing in hex
# hex does not allow for non-app related dependencies.
MYHTML_PATH = c_src/myhtml
MYHTML_STATIC = $(MYHTML_PATH)/lib/libmyhtml_static.a
MYHTMLEX_CFLAGS += -I$(MYHTML_PATH)/include

# that would be used for a dynamically linked build
# MYHTMLEX_CFLAGS += -L$(MYHTML_PATH)/lib

MYHTMLEX_LDFLAGS = -shared

# C-Node
ERL_INTERFACE = $(wildcard $(ERLANG_PATH)/../lib/erl_interface-*)
CNODE_CFLAGS = $(MYHTMLEX_CFLAGS)
CNODE_CFLAGS += -L$(ERL_INTERFACE)/lib
CNODE_CFLAGS += -I$(ERL_INTERFACE)/include
CNODE_CFLAGS += -lerl_interface -lei

# platform specific
UNAME = $(shell uname -s)
ifeq ($(wilcard Makefile.$(UNAME)),)
	include Makefile.$(UNAME)
endif

.PHONY: all

all: myhtmlex

myhtmlex: priv/myhtmlex.so
	$(MIX) compile

$(MYHTML_STATIC): $(MYHTML_PATH)
	$(MAKE) -C $(MYHTML_PATH) library

priv/myhtmlex.so: c_src/myhtmlex.c $(MYHTML_STATIC)
	$(CC) $(MYHTMLEX_CFLAGS) $(MYHTMLEX_LDFLAGS) -o $@ $< $(MYHTML_STATIC)

priv/cclient: c_src/cclient.c $(MYHTML_STATIC)
	$(CC) $(CNODE_CFLAGS) -o $@ $< $(MYHTML_STATIC)

clean: clean-myhtml
	$(RM) -r priv/myhtmlex*
	$(RM) priv/cclient
	$(RM) myhtmlex-*.tar
	$(RM) -r package-test

clean-myhtml:
	$(MAKE) -C $(MYHTML_PATH) clean

publish: clean
	$(MIX) hex.publish

