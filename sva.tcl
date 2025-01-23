# Cadence Jasper
clear -all
check_cov -init -type all 

analyze -sv "./s_box.sv"
analyze -sv "./inv_s_box.sv"
analyze -sv "./g_funct.sv"
analyze -sv "./key_expansion.sv"
analyze -sv "./AES_encrypt.sv"
analyze -sv "./AES_decrypt.sv"
analyze -sv "./AES.sv"

elaborate -top AES 

clock clk
reset ~rst_n

configure -unlimit proof

prove -all