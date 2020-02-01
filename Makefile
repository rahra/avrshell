TARGET = $(notdir $(CURDIR))

all:
	make -C src TARGET=$(TARGET)

clean:
	make -C src TARGET=$(TARGET) clean

upload:
	make -C src TARGET=$(TARGET) upload

.PHONY: clean

