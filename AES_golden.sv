class AES_golden;
    logic [  7:0] S_BOX[16][16];
    logic [  7:0] INV_S_BOX[16][16];
    logic [  7:0] RCON[10];
    logic [127:0] KEY[11];

    extern function new();
    extern function void get_round_key(logic [127:0] key);
    extern function logic [7:0] MB2(logic [7:0] x);
    extern function logic [7:0] MB(logic [7:0] x, int p);
    extern function logic [127:0] encrypt(logic [127:0] plaintext);
    extern function logic [127:0] decrypt(logic [127:0] ciphertext);
endclass

function AES_golden::new();
    S_BOX = '{'{8'h63, 8'h7c, 8'h77, 8'h7b, 8'hf2, 8'h6b, 8'h6f, 8'hc5, 8'h30, 8'h01, 8'h67, 8'h2b, 8'hfe, 8'hd7, 8'hab, 8'h76},
              '{8'hca, 8'h82, 8'hc9, 8'h7d, 8'hfa, 8'h59, 8'h47, 8'hf0, 8'had, 8'hd4, 8'ha2, 8'haf, 8'h9c, 8'ha4, 8'h72, 8'hc0},
              '{8'hb7, 8'hfd, 8'h93, 8'h26, 8'h36, 8'h3f, 8'hf7, 8'hcc, 8'h34, 8'ha5, 8'he5, 8'hf1, 8'h71, 8'hd8, 8'h31, 8'h15},
              '{8'h04, 8'hc7, 8'h23, 8'hc3, 8'h18, 8'h96, 8'h05, 8'h9a, 8'h07, 8'h12, 8'h80, 8'he2, 8'heb, 8'h27, 8'hb2, 8'h75},
              '{8'h09, 8'h83, 8'h2c, 8'h1a, 8'h1b, 8'h6e, 8'h5a, 8'ha0, 8'h52, 8'h3b, 8'hd6, 8'hb3, 8'h29, 8'he3, 8'h2f, 8'h84},
              '{8'h53, 8'hd1, 8'h00, 8'hed, 8'h20, 8'hfc, 8'hb1, 8'h5b, 8'h6a, 8'hcb, 8'hbe, 8'h39, 8'h4a, 8'h4c, 8'h58, 8'hcf},
              '{8'hd0, 8'hef, 8'haa, 8'hfb, 8'h43, 8'h4d, 8'h33, 8'h85, 8'h45, 8'hf9, 8'h02, 8'h7f, 8'h50, 8'h3c, 8'h9f, 8'ha8},
              '{8'h51, 8'ha3, 8'h40, 8'h8f, 8'h92, 8'h9d, 8'h38, 8'hf5, 8'hbc, 8'hb6, 8'hda, 8'h21, 8'h10, 8'hff, 8'hf3, 8'hd2},
              '{8'hcd, 8'h0c, 8'h13, 8'hec, 8'h5f, 8'h97, 8'h44, 8'h17, 8'hc4, 8'ha7, 8'h7e, 8'h3d, 8'h64, 8'h5d, 8'h19, 8'h73},
              '{8'h60, 8'h81, 8'h4f, 8'hdc, 8'h22, 8'h2a, 8'h90, 8'h88, 8'h46, 8'hee, 8'hb8, 8'h14, 8'hde, 8'h5e, 8'h0b, 8'hdb},
              '{8'he0, 8'h32, 8'h3a, 8'h0a, 8'h49, 8'h06, 8'h24, 8'h5c, 8'hc2, 8'hd3, 8'hac, 8'h62, 8'h91, 8'h95, 8'he4, 8'h79},
              '{8'he7, 8'hc8, 8'h37, 8'h6d, 8'h8d, 8'hd5, 8'h4e, 8'ha9, 8'h6c, 8'h56, 8'hf4, 8'hea, 8'h65, 8'h7a, 8'hae, 8'h08},
              '{8'hba, 8'h78, 8'h25, 8'h2e, 8'h1c, 8'ha6, 8'hb4, 8'hc6, 8'he8, 8'hdd, 8'h74, 8'h1f, 8'h4b, 8'hbd, 8'h8b, 8'h8a},
              '{8'h70, 8'h3e, 8'hb5, 8'h66, 8'h48, 8'h03, 8'hf6, 8'h0e, 8'h61, 8'h35, 8'h57, 8'hb9, 8'h86, 8'hc1, 8'h1d, 8'h9e},
              '{8'he1, 8'hf8, 8'h98, 8'h11, 8'h69, 8'hd9, 8'h8e, 8'h94, 8'h9b, 8'h1e, 8'h87, 8'he9, 8'hce, 8'h55, 8'h28, 8'hdf},
              '{8'h8c, 8'ha1, 8'h89, 8'h0d, 8'hbf, 8'he6, 8'h42, 8'h68, 8'h41, 8'h99, 8'h2d, 8'h0f, 8'hb0, 8'h54, 8'hbb, 8'h16}};

    INV_S_BOX = '{'{8'h52, 8'h09, 8'h6a, 8'hd5, 8'h30, 8'h36, 8'ha5, 8'h38, 8'hbf, 8'h40, 8'ha3, 8'h9e, 8'h81, 8'hf3, 8'hd7, 8'hfb},
                  '{8'h7c, 8'he3, 8'h39, 8'h82, 8'h9b, 8'h2f, 8'hff, 8'h87, 8'h34, 8'h8e, 8'h43, 8'h44, 8'hc4, 8'hde, 8'he9, 8'hcb},
                  '{8'h54, 8'h7b, 8'h94, 8'h32, 8'ha6, 8'hc2, 8'h23, 8'h3d, 8'hee, 8'h4c, 8'h95, 8'h0b, 8'h42, 8'hfa, 8'hc3, 8'h4e},
                  '{8'h08, 8'h2e, 8'ha1, 8'h66, 8'h28, 8'hd9, 8'h24, 8'hb2, 8'h76, 8'h5b, 8'ha2, 8'h49, 8'h6d, 8'h8b, 8'hd1, 8'h25},
                  '{8'h72, 8'hf8, 8'hf6, 8'h64, 8'h86, 8'h68, 8'h98, 8'h16, 8'hd4, 8'ha4, 8'h5c, 8'hcc, 8'h5d, 8'h65, 8'hb6, 8'h92},
                  '{8'h6c, 8'h70, 8'h48, 8'h50, 8'hfd, 8'hed, 8'hb9, 8'hda, 8'h5e, 8'h15, 8'h46, 8'h57, 8'ha7, 8'h8d, 8'h9d, 8'h84},
                  '{8'h90, 8'hd8, 8'hab, 8'h00, 8'h8c, 8'hbc, 8'hd3, 8'h0a, 8'hf7, 8'he4, 8'h58, 8'h05, 8'hb8, 8'hb3, 8'h45, 8'h06},
                  '{8'hd0, 8'h2c, 8'h1e, 8'h8f, 8'hca, 8'h3f, 8'h0f, 8'h02, 8'hc1, 8'haf, 8'hbd, 8'h03, 8'h01, 8'h13, 8'h8a, 8'h6b},
                  '{8'h3a, 8'h91, 8'h11, 8'h41, 8'h4f, 8'h67, 8'hdc, 8'hea, 8'h97, 8'hf2, 8'hcf, 8'hce, 8'hf0, 8'hb4, 8'he6, 8'h73},
                  '{8'h96, 8'hac, 8'h74, 8'h22, 8'he7, 8'had, 8'h35, 8'h85, 8'he2, 8'hf9, 8'h37, 8'he8, 8'h1c, 8'h75, 8'hdf, 8'h6e},
                  '{8'h47, 8'hf1, 8'h1a, 8'h71, 8'h1d, 8'h29, 8'hc5, 8'h89, 8'h6f, 8'hb7, 8'h62, 8'h0e, 8'haa, 8'h18, 8'hbe, 8'h1b},
                  '{8'hfc, 8'h56, 8'h3e, 8'h4b, 8'hc6, 8'hd2, 8'h79, 8'h20, 8'h9a, 8'hdb, 8'hc0, 8'hfe, 8'h78, 8'hcd, 8'h5a, 8'hf4},
                  '{8'h1f, 8'hdd, 8'ha8, 8'h33, 8'h88, 8'h07, 8'hc7, 8'h31, 8'hb1, 8'h12, 8'h10, 8'h59, 8'h27, 8'h80, 8'hec, 8'h5f},
                  '{8'h60, 8'h51, 8'h7f, 8'ha9, 8'h19, 8'hb5, 8'h4a, 8'h0d, 8'h2d, 8'he5, 8'h7a, 8'h9f, 8'h93, 8'hc9, 8'h9c, 8'hef},
                  '{8'ha0, 8'he0, 8'h3b, 8'h4d, 8'hae, 8'h2a, 8'hf5, 8'hb0, 8'hc8, 8'heb, 8'hbb, 8'h3c, 8'h83, 8'h53, 8'h99, 8'h61},
                  '{8'h17, 8'h2b, 8'h04, 8'h7e, 8'hba, 8'h77, 8'hd6, 8'h26, 8'he1, 8'h69, 8'h14, 8'h63, 8'h55, 8'h21, 8'h0c, 8'h7d}};

    RCON = '{8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80, 8'h1B, 8'h36};
endfunction

function void AES_golden::get_round_key(logic [127:0] key);
    logic [31:0] temp;
    KEY[0] = key;
    for (int i = 1; i < 11; i++) begin
        temp = KEY[i-1][31:0];
        temp = {temp[23:16], temp[15:8], temp[7:0], temp[31:24]};
        for (int j = 0; j < 4; j++) begin
            temp[8*j+:8] = S_BOX[temp[8*j+4+:4]][temp[8*j+:4]];
        end
        temp = temp ^ {RCON[i-1], 24'b0};

        KEY[i][127:96] = temp ^ KEY[i-1][127:96];
        KEY[i][ 95:64] = KEY[i][127:96] ^ KEY[i-1][ 95:64];
        KEY[i][ 63:32] = KEY[i][ 95:64] ^ KEY[i-1][ 63:32];
        KEY[i][ 31: 0] = KEY[i][ 63:32] ^ KEY[i-1][ 31: 0];
    end
endfunction

function logic [7:0] AES_golden::MB2(logic [7:0] x);
    MB2 = x[7] ? ((x << 1) ^ 8'h1b) : x << 1;
endfunction

function logic [7:0] AES_golden::MB(logic [7:0] x, int p);
    case (p)
        'd1: MB = x;
        'd2: MB = MB2(x);
        'd3: MB = MB2(x) ^ x;
        'd9: MB = MB2(MB2(MB2(x))) ^ x;
        'd11:MB = MB2(MB2(MB2(x)) ^ x) ^ x;
        'd13:MB = MB2(MB2(MB2(x) ^ x)) ^ x;
        'd14:MB = MB2(MB2(MB2(x) ^ x) ^ x);
    endcase
endfunction

function logic [127:0] AES_golden::encrypt(logic [127:0] plaintext);
    logic [127:0] sub_byte, shift_row, mixed_columns, add_round_key;
    add_round_key = plaintext ^ KEY[0];

    for (int Nr = 1; Nr < 11; Nr++) begin
        for (int i = 0; i < 16; i++) begin
            sub_byte[8*i+:8] = S_BOX[add_round_key[8*i+4+:4]][add_round_key[8*i+:4]];
        end

        shift_row = {sub_byte[127:120], sub_byte[ 87: 80], sub_byte[ 47: 40], sub_byte[  7: 0],
                     sub_byte[ 95: 88], sub_byte[ 55: 48], sub_byte[ 15:  8], sub_byte[103:96],
                     sub_byte[ 63: 56], sub_byte[ 23: 16], sub_byte[111:104], sub_byte[ 71:64],
                     sub_byte[ 31: 24], sub_byte[119:112], sub_byte[ 79: 72], sub_byte[ 39:32]};

        if (Nr != 10) begin
            for (int i = 0; i < 4; i++) begin
                mixed_columns[32*i+24+:8] = MB(shift_row[32*i+24+:8], 2) ^ MB(shift_row[32*i+16+:8], 3) ^ MB(shift_row[32*i+8+:8], 1) ^ MB(shift_row[32*i+:8], 1);
                mixed_columns[32*i+16+:8] = MB(shift_row[32*i+24+:8], 1) ^ MB(shift_row[32*i+16+:8], 2) ^ MB(shift_row[32*i+8+:8], 3) ^ MB(shift_row[32*i+:8], 1);
                mixed_columns[32*i+8 +:8] = MB(shift_row[32*i+24+:8], 1) ^ MB(shift_row[32*i+16+:8], 1) ^ MB(shift_row[32*i+8+:8], 2) ^ MB(shift_row[32*i+:8], 3);
                mixed_columns[32*i   +:8] = MB(shift_row[32*i+24+:8], 3) ^ MB(shift_row[32*i+16+:8], 1) ^ MB(shift_row[32*i+8+:8], 1) ^ MB(shift_row[32*i+:8], 2);
            end
            add_round_key = mixed_columns ^ KEY[Nr];
        end else begin
            add_round_key = shift_row ^ KEY[Nr];
        end
        
    end
    return add_round_key;
endfunction

function logic [127:0] AES_golden::decrypt(logic [127:0] ciphertext);
    logic [127:0] inv_sub_byte, inv_shift_row, inv_mixed_column, add_round_key;
    inv_mixed_column = ciphertext ^ KEY[10];

    for (int Nr = 9; Nr >= 0; Nr--) begin
        inv_shift_row = {inv_mixed_column[127:120], inv_mixed_column[ 23: 16], inv_mixed_column[ 47: 40], inv_mixed_column[ 71:64],
                         inv_mixed_column[ 95: 88], inv_mixed_column[119:112], inv_mixed_column[ 15:  8], inv_mixed_column[ 39:32],
                         inv_mixed_column[ 63: 56], inv_mixed_column[ 87: 80], inv_mixed_column[111:104], inv_mixed_column[  7: 0],
                         inv_mixed_column[ 31: 24], inv_mixed_column[ 55: 48], inv_mixed_column[ 79: 72], inv_mixed_column[103:96]};
        
        for (int i = 0; i < 16; i++) begin
            inv_sub_byte[8*i+:8] = INV_S_BOX[inv_shift_row[8*i+4+:4]][inv_shift_row[8*i+:4]];
        end

        add_round_key = inv_sub_byte ^ KEY[Nr];

        if (Nr != 0) begin
            for (int i = 0; i < 4; i++) begin
                inv_mixed_column[32*i+24+:8] = MB(add_round_key[32*i+24+:8], 14) ^ MB(add_round_key[32*i+16+:8], 11) ^ MB(add_round_key[32*i+8+:8], 13) ^ MB(add_round_key[32*i+:8], 9 );
                inv_mixed_column[32*i+16+:8] = MB(add_round_key[32*i+24+:8], 9 ) ^ MB(add_round_key[32*i+16+:8], 14) ^ MB(add_round_key[32*i+8+:8], 11) ^ MB(add_round_key[32*i+:8], 13);
                inv_mixed_column[32*i+8 +:8] = MB(add_round_key[32*i+24+:8], 13) ^ MB(add_round_key[32*i+16+:8], 9 ) ^ MB(add_round_key[32*i+8+:8], 14) ^ MB(add_round_key[32*i+:8], 11);
                inv_mixed_column[32*i   +:8] = MB(add_round_key[32*i+24+:8], 11) ^ MB(add_round_key[32*i+16+:8], 13) ^ MB(add_round_key[32*i+8+:8], 9 ) ^ MB(add_round_key[32*i+:8], 14);
            end
        end
    end
    return add_round_key;
endfunction