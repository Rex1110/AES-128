run:
	irun -sv AES_tb.sv
clean:
	rm -rf *.out *.log *.key *.rc *.conf *.history BSSLib.lib++ nWaveLog vfastLog INCA_libs *.fsdb *.vcd verdiLog *.el
	rm -rf csrc simv.daidir vdCovLog *.vdb simv .fsm.sch.verilog.xml *.h cov_work jgproject