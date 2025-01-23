`include "s_box.sv"
`include "inv_s_box.sv"
`include "g_funct.sv"
`include "key_expansion.sv"
`include "AES_encrypt.sv"
`include "AES_decrypt.sv"
module AES(
    input                   clk,
    input                   rst_n,

    input                   set_key_i,
    input           [127:0] key_i,
    
    input                   encrypt_i,
    input           [127:0] plaintext_i,

    input                   decrypt_i,
    input           [127:0] ciphertext_i,

    output  logic           set_key_enable_o,
    output  logic           encrypt_busy_o,
    output  logic           decrypt_busy_o,

    output  logic           gen_key_done_o,
    output  logic           encrypt_done_o,
    output  logic           decrypt_done_o,
    output  logic   [127:0] plaintext_o,
    output  logic   [127:0] ciphertext_o
);

    logic [127:0] block, sub_byte;
    logic [31:0] rot_word;
    logic [127:0] encrypt_round_key, decrypt_round_key;
    logic [3:0] select_encrypt_round_key, select_decrypt_round_key;
    logic gen_key_busy;
    
    logic encrypt_enable, decrypt_enbale;

    assign set_key_enable_o = ~encrypt_busy_o && ~decrypt_busy_o;
    assign encrypt_enable = encrypt_i && (~set_key_i && ~gen_key_busy);
    assign decrypt_enbale = decrypt_i && (~set_key_i && ~gen_key_busy);
    
    key_expansion key_expansion_(
        .clk                        (clk                        ),
        .rst_n                      (rst_n                      ),
        .set_key                    (set_key_enable_o && set_key_i),
        .key                        (key_i                      ),
        .select_encrypt_round_key   (select_encrypt_round_key   ),
        .encrypt_round_key          (encrypt_round_key          ),
        .select_decrypt_round_key   (select_decrypt_round_key   ),
        .decrypt_round_key          (decrypt_round_key          ),
        .gen_key_done               (gen_key_done_o             ),
        .gen_key_busy               (gen_key_busy               ),

        .rot_word                   (rot_word                   ),
        .sub_byte                   (sub_byte[31:0]             )
    );

    AES_encrypt AES_encrypt_(
        .clk                        (clk                        ),
        .rst_n                      (rst_n                      ),
        .encrypt                    (encrypt_enable             ),
        .plaintext                  (plaintext_i                ),
        .select_encrypt_round_key   (select_encrypt_round_key   ),
        .encrypt_round_key          (encrypt_round_key          ),
        .encrypt_done               (encrypt_done_o             ),
        .encrypt_busy               (encrypt_busy_o             ),

        .block                      (block                      ),
        .sub_byte                   (sub_byte                   ),
        .ciphertext_o               (ciphertext_o               )
    );

    generate
        for (genvar i = 0; i < 16; i++) begin
            if (i < 4) begin
                s_box s_box_(
                    .in (gen_key_busy ? rot_word[8*i+7:8*i] : block[8*i+7:8*i]),
                    .out(sub_byte[8*i+7:8*i])
                );
            end else begin
                s_box s_box_(
                    .in (block[8*i+7:8*i]   ),
                    .out(sub_byte[8*i+7:8*i])
                );
            end
        end
    endgenerate

    AES_decrypt AES_decrypt_(
        .clk                        (clk                        ),
        .rst_n                      (rst_n                      ),
        .decrypt                    (decrypt_enbale             ),
        .ciphertext                 (ciphertext_i               ),
        .select_decrypt_round_key   (select_decrypt_round_key   ),
        .decrypt_round_key          (decrypt_round_key          ),
        .decrypt_done               (decrypt_done_o             ),
        .decrypt_busy               (decrypt_busy_o             ),
        .plaintext_o                (plaintext_o                )
    );

    when_key_expansion_encrypt_idle: assert property (
        @(posedge clk) disable iff (~rst_n) (
            (key_expansion_.state !== 4'd0) |-> (AES_encrypt_.state === 4'd0)
        )
    );

    when_key_expansion_decrypt_idle: assert property (
        @(posedge clk) disable iff (~rst_n) (
            (key_expansion_.state !== 4'd0) |-> (AES_decrypt_.state === 4'd10)
        )
    );

endmodule