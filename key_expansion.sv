module key_expansion(
    input                       clk,
    input                       rst_n,
    input                       set_key,
    input           [127:0]     key,
    input           [  3:0]     select_encrypt_round_key,
    output  logic   [127:0]     encrypt_round_key,
    input           [  3:0]     select_decrypt_round_key,
    output  logic   [127:0]     decrypt_round_key,
    output  logic               gen_key_done,
    output  logic               gen_key_busy,

    output  logic   [31:0]      rot_word,
    input           [31:0]      sub_byte
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
               Nr10  = 10,
               FINISH= 11;

    logic [127:0] key_reg[11];
    logic [127:0] in, out;
    logic [3:0] state, next_state;

    assign gen_key_done = (state == FINISH);
    assign gen_key_busy = (state != Nr0);
    assign encrypt_round_key = key_reg[select_encrypt_round_key];
    assign decrypt_round_key = key_reg[select_decrypt_round_key];

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            state <= Nr0;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        case (state)
            Nr0    : next_state = set_key ? Nr1 : Nr0;
            Nr1    : next_state = Nr2;
            Nr2    : next_state = Nr3;
            Nr3    : next_state = Nr4;
            Nr4    : next_state = Nr5;
            Nr5    : next_state = Nr6;
            Nr6    : next_state = Nr7;
            Nr7    : next_state = Nr8;
            Nr8    : next_state = Nr9;
            Nr9    : next_state = Nr10;
            Nr10   : next_state = FINISH;
            FINISH : next_state = Nr0;
            default: next_state = Nr0;
        endcase
    end

    always_comb begin
        case (state)
            Nr1     :in = key_reg[0];
            Nr2     :in = key_reg[1];
            Nr3     :in = key_reg[2];
            Nr4     :in = key_reg[3];
            Nr5     :in = key_reg[4];
            Nr6     :in = key_reg[5];
            Nr7     :in = key_reg[6];
            Nr8     :in = key_reg[7];
            Nr9     :in = key_reg[8];
            Nr10    :in = key_reg[9];
            default :in = 'd0;
        endcase
    end

    g_funct g_funct_(
        .in         (in      ),
        .round      (state   ),
        .rot_word   (rot_word),
        .sub_byte   (sub_byte),
        .out        (out     )
    );

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < 11; i++) begin
                key_reg[i] <= 128'd0;
            end
        end else begin
            key_reg[0] <= set_key ? key : key_reg[0];
            for (int i = 1; i < 11; i++) begin
                key_reg[i] <= (state == i) ? out : key_reg[i];
            end
        end
    end
    
endmodule