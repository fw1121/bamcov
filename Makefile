
CC=gcc
CFLAGS=-std=c99 -Wall -lm -lz -llzma -lbz2 -lcurl -pthread
INCLUDE=-Ihtslib

## From htslib Makefile: specify shlib flavor based on platform
# $(shell), :=, and ifeq/.../endif are GNU Make-specific.  If you don't have
# GNU Make, comment out the parts of these conditionals that don't apply.
ifneq "$(origin PLATFORM)" "file"
PLATFORM := $(shell uname -s)
endif
ifeq "$(PLATFORM)" "Darwin"
HTSLIB=libhts.dylib
else ifeq "$(findstring CYGWIN,$(PLATFORM))" "CYGWIN"
HTSLIB=cyghts-$(LIBHTS_SOVERSION).dll
else ifeq "$(findstring MSYS,$(PLATFORM))" "MSYS"
HTSLIB=hts-$(LIBHTS_SOVERSION).dll
else
HTSLIB=libhts.so
endif

all: bamcov

clean:
	rm -v bamcov

html-header.hpp: bamcov.html
	xxd -i $^ > $@

bamcov: bamcov.c htslib/libhts.a
	gcc $(INCLUDE) -o $@ $^ $(CFLAGS)

bamcov-dynamic: bamcov.c htslib/$(HTSLIB)
	$(CC) $(CCFLAGS) $(INCLUDE) -o $@ bamcov.c $(CFLAGS) -Lhtslib -lhts

test: bamcov
	./bamcov -H test.bam | column -ts$$'\t'
	./bamcov -m test.bam

htslib/Makefile:
	git submodule update --init --recursive

htslib/libhts.a: htslib/Makefile
	cd htslib && make libhts.a

htslib/$(HTSLIB): htslib/Makefile
	cd htslib && make $(HTSLIB)

bamcov.tar.gz: bamcov bamcov.c README.md Makefile test.bam test.bam.bai
	tar zcvf $@ $^
