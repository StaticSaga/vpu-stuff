GAS = /home/pi/binutils-vc4/gas/as-new
OBJCOPY = /home/pi/binutils-vc4/binutils/objcopy

# TODO: improve this

.PHONY: run clean
run: build/demo build/test
	sudo ./build/demo
clean:
	rm build/*

build/test.elf: test.s
	$(GAS) test.s -o build/test.elf

build/test: build/test.elf 
	$(OBJCOPY) -O binary build/test.elf build/test

external/mailbox.c:
	cp /opt/vc/src/hello_pi/hello_fft/mailbox.c external/
external/mailbox.h:
	cp /opt/vc/src/hello_pi/hello_fft/mailbox.h external/

build/demo: main.c external/mailbox.c external/mailbox.h
	gcc main.c external/mailbox.c -o build/demo -Iexternal
