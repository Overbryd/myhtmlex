MIX = mix
CFLAGS = -g -O3 -std=c99 -pedantic -Wcomment -Wall -Wextra
# turn warnings into errors
CFLAGS += -Werror
# ignore unused parameter warnings
CFLAGS += -Wno-unused-parameter
# ignore missing field initializers warning (because of `static ErlNifFunc funcs[]`)
CFLAGS += -Wno-missing-field-initializers

# set erlang include path
ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
CFLAGS += -I$(ERLANG_PATH)

# either we have not fetched myhtml, assume its in a sibling directory
ifeq ($(wildcard deps/myhtml),)
	MYHTML_PATH = ../myhtml
# or we fetched it as a mix dependency
else
	MYHTML_PATH = deps/myhtml
endif

CFLAGS += -I$(MYHTML_PATH)/source

# I have no idea yet what this does, something for macOS presuambly
ifeq ($(shell uname),Darwin)
	LDFLAGS += -dynamiclib -undefined dynamic_lookup
endif

.PHONY: all myhtml clear

all: myhtml

myhtml:
	$(MIX) compile

priv/myhtmlex.so: src/myhtmlex.c
	$(MAKE) -C $(MYHTML_PATH) library
	$(CC) $(CFLAGS) -shared $(LDFLAGS) -o $@ src/myhtmlex.c $(MYHTML_PATH)/lib/libmyhtml_static.a

clean:
	$(MIX) clean
	$(MAKE) -C $(MYHTML_PATH) clean
	$(RM) priv/myhtmlex.so

