module AES_decrypt(
    input                   clk,
    input                   rst_n,

    input                   decrypt,
    input           [127:0] ciphertext,

    output  logic   [  3:0] select_decrypt_round_key,
    input           [127:0] decrypt_round_key,
    output  logic           decrypt_done,
    output  logic           decrypt_busy,

    output  logic   [127:0] plaintext_o
);

    localparam Nr0   =  0,
               Nr1   =  1,
               Nr2   =  2,
               Nr3   =  3,
               Nr4   =  4,
               Nr5   =  5,
               Nr6   =  6,
               Nr7   =  7,
               Nr8   =  8,
               Nr9   =  9,
               Nr10  = 10;

    logic [3:0] state, next_state;
    logic [127:0] block, inv_shift_row, inv_sub_byte, inv_mixed_columns, add_round_key;

    assign select_decrypt_round_key = state;
    assign decrypt_done = (state == Nr0);
    assign decrypt_busy = (state != Nr10);
    assign plaintext_o = add_round_key;

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            state <= Nr10;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        case (state)
            Nr10   : next_state = decrypt ? Nr9 : Nr10;
            Nr9    : next_state = Nr8;
            Nr8    : next_state = Nr7;
            Nr7    : next_state = Nr6;
            Nr6    : next_state = Nr5;
            Nr5    : next_state = Nr4;
            Nr4    : next_state = Nr3;
            Nr3    : next_state = Nr2;
            Nr2    : next_state = Nr1;
            Nr1    : next_state = Nr0;
            Nr0    : next_state = Nr10;
            default: next_state = Nr10;
        endcase
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            block <= 128'd0;
        end else if (state == Nr10) begin
            block <= decrypt ? (ciphertext ^ decrypt_round_key) : block;
        end else begin
            block <= inv_mixed_columns;
        end
    end

    assign inv_shift_row[127:96] = {block[127:120], block[ 23: 16], block[ 47: 40], block[ 71:64]};
    assign inv_shift_row[ 95:64] = {block[ 95: 88], block[119:112], block[ 15:  8], block[ 39:32]};
    assign inv_shift_row[ 63:32] = {block[ 63: 56], block[ 87: 80], block[111:104], block[  7: 0]};
    assign inv_shift_row[ 31: 0] = {block[ 31: 24], block[ 55: 48], block[ 79: 72], block[103:96]};

    generate
        for (genvar i = 0; i < 16; i++) begin
            inv_s_box inv_s_box_(
                .in (inv_shift_row[8*i+7:8*i]),
                .out(inv_sub_byte[8*i+7:8*i] )
            );
        end
    endgenerate

    assign add_round_key = inv_sub_byte ^ decrypt_round_key;

    function logic [7:0] MC2(logic [7:0] x);
        MC2 = x[7] ? ((x << 1) ^ 8'h1b) : x << 1;
    endfunction

    function logic [7:0] MC(logic [7:0] x, logic [3:0] p);
        case (p)
            'd1: MC = x;
            'd2: MC = MC2(x);
            'd3: MC = MC2(x) ^ x;
            'd9: MC = MC2(MC2(MC2(x))) ^ x;
            'd11:MC = MC2(MC2(MC2(x)) ^ x) ^ x;
            'd13:MC = MC2(MC2(MC2(x) ^ x)) ^ x;
            'd14:MC = MC2(MC2(MC2(x) ^ x) ^ x);
        endcase
    endfunction

    generate 
        for(genvar i = 0; i < 4; i++) begin
            assign inv_mixed_columns[32*i+31:32*i+24] = MC(add_round_key[32*i+31:32*i+24], 4'd14) ^ MC(add_round_key[32*i+23:32*i+16], 4'd11) ^ MC(add_round_key[32*i+15:32*i+8], 4'd13) ^ MC(add_round_key[32*i+7:32*i], 4'd9 );
            assign inv_mixed_columns[32*i+23:32*i+16] = MC(add_round_key[32*i+31:32*i+24], 4'd9 ) ^ MC(add_round_key[32*i+23:32*i+16], 4'd14) ^ MC(add_round_key[32*i+15:32*i+8], 4'd11) ^ MC(add_round_key[32*i+7:32*i], 4'd13);
            assign inv_mixed_columns[32*i+15:32*i+ 8] = MC(add_round_key[32*i+31:32*i+24], 4'd13) ^ MC(add_round_key[32*i+23:32*i+16], 4'd9 ) ^ MC(add_round_key[32*i+15:32*i+8], 4'd14) ^ MC(add_round_key[32*i+7:32*i], 4'd11);
            assign inv_mixed_columns[32*i+ 7:32*i   ] = MC(add_round_key[32*i+31:32*i+24], 4'd11) ^ MC(add_round_key[32*i+23:32*i+16], 4'd13) ^ MC(add_round_key[32*i+15:32*i+8], 4'd9 ) ^ MC(add_round_key[32*i+7:32*i], 4'd14);
        end
    endgenerate

endmodule