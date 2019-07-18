TARGET = $(notdir $(CURDIR))

all:
	make -C src TARGET=$(TARGET)

clean:
	make -C src TARGET=$(TARGET) clean

.PHONY: clean

