module g_funct(
    input           [127:0] in,
    input           [  3:0] round,
    output  logic   [ 31:0] rot_word,
    input           [ 31:0] sub_byte,
    output  logic   [127:0] out
);

    logic [31:0] rcon;
    
    assign rot_word = {in[23:0], in[31:24]};
    
    assign rcon = (round == 8'd9 ) ? sub_byte ^ (8'h1B << 8'd24):
                  (round == 8'd10) ? sub_byte ^ (8'h36 << 8'd24):
                                     sub_byte ^ (32'd1 << (round + 8'd23));

    assign out[127:96] = in[127:96] ^ rcon;
    assign out[ 95:64] = in[ 95:64] ^ out[127:96];
    assign out[ 63:32] = in[ 63:32] ^ out[ 95:64];
    assign out[ 31: 0] = in[ 31: 0] ^ out[ 63:32];
endmodule