#Make file for the DSLogic project
#2015 Dimitar Penev dpn@switchfin.org

export PATH := $(PATH):/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64/
 
DEVICE = xc6slx9-tqg144-2
TARGET = DSLogic

default: $(TARGET)33.bin
 
MY_VERILOG_FILES := $(shell find ./src/ -name '*.v')

#Synthesis ============================================================================================================================================
#build the ngc (netlist) file
$(TARGET).ngc:	$(MY_VERILOG_FILES)
	echo $(MY_VERILOG_FILES) | sed "s/ /\nVerilog work /g" | sed "1s/^/Verilog work /" > $(TARGET).prj
	xst -intstyle ise  -ifn ./src/$(TARGET).xst

#Translate  ==========================
#Build .ndg (Native Generic Database) file
$(TARGET).ngd:	$(TARGET).ngc ./src/$(TARGET).ucf
	ngdbuild -intstyle ise -dd _ngo -sd ./src/ipcore_dir -nt timestamp -uc ./src/$(TARGET).ucf -p xc6slx9-tqg144-2 $(TARGET).ngc $(TARGET).ngd	

#Mapping, ============================
#Build .pcf (Physical Constraints File) and .ncd (Native Circuit Description) file
$(TARGET).pcf:	$(TARGET).ngd
	map -intstyle ise -p $(DEVICE) -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o $(TARGET)_map.ncd $(TARGET).ngd $(TARGET).pcf

#Placing and Routing  ================
parout.ncd: $(TARGET).pcf
	par -w -intstyle ise -ol high -mt off $(TARGET)_map.ncd parout.ncd $(TARGET).pcf

#Generating bit stream ===============
$(TARGET).bit:	parout.ncd
	bitgen -w -intstyle ise parout.ncd $(TARGET).bit $(TARGET).pcf

#make bin file suitable for fx2 loading 
$(TARGET)33.bin: $(TARGET).bit
	promgen -w -p bin -o $(TARGET)33.bin -u 0x0 $(TARGET).bit


install: $(TARGET)33.bin
	cp $(TARGET)33.bin ../DSLogic/DSLogic-gui/res/

# Clean ===============================================================================================================================================
clean:
	find -maxdepth 1 ! -name 'NEWS' ! -name 'COPYING' ! -name 'README' ! -name 'Makefile' ! -name $(TARGET)33.bin -type f -exec rm -f {} +
	rm -rf _ngo/ _xmsgs/ xlnx_auto_0_xdb/ xst/

#Simulation ===========================================================================================================================================
#Add -Wall if you need all warnings
$(TARGET): $(MY_VERILOG_FILES) ./tb/DSLogic_tb.v
	iverilog -o DSLogic -I ./src/i2c/ -I ./tb/ -y /opt/Xilinx/14.7/ISE_DS/ISE/verilog/src/unisims/ ./tb/DSLogic_tb.v \
	/opt/Xilinx/14.7/ISE_DS/ISE/verilog/src/XilinxCoreLib/FIFO_GENERATOR_V8_2.v /opt/Xilinx/14.7/ISE_DS/ISE/verilog/src/glbl.v $(MY_VERILOG_FILES)

$(TARGET).lxt2: $(TARGET)
	vvp $(TARGET) -lxt2

sim:	$(TARGET).lxt2
	gtkwave $(TARGET).lxt2
