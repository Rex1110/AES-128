module AES_encrypt(
    input                   clk,
    input                   rst_n,
    
    input                   encrypt,
    input           [127:0] plaintext,

    output  logic   [  3:0] select_encrypt_round_key,
    input           [127:0] encrypt_round_key,
    output  logic           encrypt_done,
    output  logic           encrypt_busy,

    output  logic   [127:0] ciphertext_o,

    output  logic   [127:0] block,
    input           [127:0] sub_byte
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
    logic [127:0] round_key, shift_row, mixed_columns;

    assign select_encrypt_round_key = state;
    assign encrypt_done = (state == Nr10);
    assign encrypt_busy = (state != Nr0);
    assign ciphertext_o = shift_row ^ encrypt_round_key;

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            state <= Nr0;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        case (state)
            Nr0    : next_state = encrypt ? Nr1 : Nr0;
            Nr1    : next_state = Nr2;
            Nr2    : next_state = Nr3;
            Nr3    : next_state = Nr4;
            Nr4    : next_state = Nr5;
            Nr5    : next_state = Nr6;
            Nr6    : next_state = Nr7;
            Nr7    : next_state = Nr8;
            Nr8    : next_state = Nr9;
            Nr9    : next_state = Nr10;
            Nr10   : next_state = Nr0;
            default: next_state = Nr0;
        endcase
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            block <= 128'd0;
        end else if (state == Nr0) begin
            block <= encrypt ? (plaintext ^ encrypt_round_key) : block;
        end else begin
            block <= mixed_columns ^ encrypt_round_key;
        end
    end

    assign shift_row[127:96] = {sub_byte[127:120], sub_byte[ 87: 80], sub_byte[ 47: 40], sub_byte[  7: 0]};
    assign shift_row[ 95:64] = {sub_byte[ 95: 88], sub_byte[ 55: 48], sub_byte[ 15:  8], sub_byte[103:96]};
    assign shift_row[ 63:32] = {sub_byte[ 63: 56], sub_byte[ 23: 16], sub_byte[111:104], sub_byte[ 71:64]};
    assign shift_row[ 31: 0] = {sub_byte[ 31: 24], sub_byte[119:112], sub_byte[ 79: 72], sub_byte[ 39:32]};

    function logic [7:0] MC2(logic [7:0] x);
        MC2 = x[7] ? ((x << 1) ^ 8'h1b) : x << 1;
    endfunction

    function logic [7:0] MC(logic [7:0] x, logic [3:0] p);
        case (p)
            4'd1: MC = x;
            4'd2: MC = MC2(x);
            4'd3: MC = MC2(x) ^ x;
            4'd9: MC = MC2(MC2(MC2(x))) ^ x;
            4'd11:MC = MC2(MC2(MC2(x)) ^ x) ^ x;
            4'd13:MC = MC2(MC2(MC2(x) ^ x)) ^ x;
            4'd14:MC = MC2(MC2(MC2(x) ^ x) ^ x);
        endcase
    endfunction

    generate 
        for(genvar i = 0;i < 4;i++) begin
            assign mixed_columns[32*i+31:32*i+24] = MC(shift_row[32*i+31:32*i+24], 4'd2) ^ MC(shift_row[32*i+23:32*i+16], 4'd3) ^ MC(shift_row[32*i+15:32*i+8], 4'd1) ^ MC(shift_row[32*i+7:32*i], 4'd1);
            assign mixed_columns[32*i+23:32*i+16] = MC(shift_row[32*i+31:32*i+24], 4'd1) ^ MC(shift_row[32*i+23:32*i+16], 4'd2) ^ MC(shift_row[32*i+15:32*i+8], 4'd3) ^ MC(shift_row[32*i+7:32*i], 4'd1);
            assign mixed_columns[32*i+15:32*i+ 8] = MC(shift_row[32*i+31:32*i+24], 4'd1) ^ MC(shift_row[32*i+23:32*i+16], 4'd1) ^ MC(shift_row[32*i+15:32*i+8], 4'd2) ^ MC(shift_row[32*i+7:32*i], 4'd3);
            assign mixed_columns[32*i+ 7:32*i   ] = MC(shift_row[32*i+31:32*i+24], 4'd3) ^ MC(shift_row[32*i+23:32*i+16], 4'd1) ^ MC(shift_row[32*i+15:32*i+8], 4'd1) ^ MC(shift_row[32*i+7:32*i], 4'd2);
        end
    endgenerate

endmodule