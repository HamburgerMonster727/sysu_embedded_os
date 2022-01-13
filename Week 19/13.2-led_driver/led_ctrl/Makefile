INSTALLDIR	= /opt/tftp

ifneq ($(KERNELRELEASE),)
obj-m:=led.o
else
KERNELDIR:=/usr/local/src/s4418/s5p4418-kitkat/kernel
CROSS_COMPILE:=/usr/local/src/s4418/s5p4418-kitkat/prebuilts/gcc/linux-x86/arm/arm-eabi-4.7/bin/arm-eabi-

PWD:=$(shell pwd)

default:
	$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KERNELDIR) M=$(PWD) modules

clean:
	rm -rf *.o *.order .*.cmd *.ko *.mod.c *.symvers
endif

install: led.ko
	mkdir -p $(INSTALLDIR)
	cp --target-dir=$(INSTALLDIR) led.ko
