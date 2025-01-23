`include "AES.sv"
`include "AES_golden.sv"

class transaction;
    rand logic encrypt, decrypt;
    rand logic [127:0] plaintext, ciphertext;
endclass

module AES_tb();

    string your_plaintext;
    transaction tr_encrypt, tr_decrypt;
    bit clk, rst_n;
    logic set_key, encrypt, decrypt, encrypt_done, decrypt_done, gen_key_done, encrypt_busy, decrypt_busy, set_key_enable;
    logic [127:0] key, plaintext, ciphertext, plaintext_o, ciphertext_o, your_key;
    logic [127:0] ciphertext_q[$];
    AES_golden AES_t;

    AES AES_(
        .clk              (clk            ),
        .rst_n            (rst_n          ),
        .set_key_i        (set_key        ),
        .key_i            (key            ),
        .encrypt_i        (encrypt        ),
        .plaintext_i      (plaintext      ),
        .decrypt_i        (decrypt        ),
        .ciphertext_i     (ciphertext     ),
        .set_key_enable_o (set_key_enable ),
        .encrypt_busy_o   (encrypt_busy   ),
        .decrypt_busy_o   (decrypt_busy   ),
        .gen_key_done_o   (gen_key_done   ),
        .encrypt_done_o   (encrypt_done   ),
        .decrypt_done_o   (decrypt_done   ),
        .plaintext_o      (plaintext_o    ),
        .ciphertext_o     (ciphertext_o   )
    );

    always #1 clk = ~clk;

    initial begin 

        
        your_plaintext = "This AES-128 system is designed to minimize area, ";
        your_plaintext = {your_plaintext, "featuring modules for Key Expansion, Encrypt, Decrypt, 16 S-box, and 16 Inverse S-box. "};
        your_plaintext = {your_plaintext, "To optimize resources, the first 4 S-boxes are shared between the Key Expansion and Encrypt modules. "};
        your_plaintext = {your_plaintext, "The key schedule requires 10 rounds of computation and includes a finish state to prevent decryption from using incomplete round keys. "};
        your_plaintext = {your_plaintext, "Each encryption or decryption operation takes 10 clock cycles, and key reconfiguration can only occur after current operations are fully completed."};
        your_key = 128'h5468_6174_7320_756e_6720_4675_6d79_204b;

        tr_decrypt = new();
        tr_encrypt = new();
        AES_t = new();

        self(your_plaintext, your_key);

        $display("\n\n********************************************");
        $display("                Random test");
        $display("********************************************");

        for (int i = 0; i <= 100; i+=25) begin
            for (int j = 0; j <= 100; j+=25) begin
                set_key_task();
                $display("\n===========================================================================================");
                $display("======================== Encrypt ratio = %0d%%, decrypt ratio = %0d%% =======================", i, j);
                $display("===========================================================================================");
                fork
                    repeat(30) encrypt_task(i);
                    repeat(30) decrypt_task(j);
                join
            end
        end
        $finish;
    end


    task self(string your_plaintext, logic [127:0] your_key);

        rst_n     <= 1'b0;
        set_key   <= 1'b0;
        encrypt   <= 1'b0;
        decrypt   <= 1'b0;
        plaintext <= 128'b0;
        set_key   <= 1'b0;
        @(posedge clk);
        rst_n     <= 1'b1;
        key       <= your_key;
        set_key   <= 1'b1;
        wait(set_key_enable);
        @(posedge clk);
        set_key   <= 1'b0;
        wait(gen_key_done);
        
        $display("\n\n********************************************\n");
        $display("Plaintext:");
        $display("%s", your_plaintext);
        $display("\nKey:");
        $display("0x%h_%h_%h_%h", key[127:96], key[95:64], key[63:32], key[31:0]);
        $display("\n********************************************\n");

        $display("");
        $display("****************************************************************************************************");
        $display("                                            AES encrypt                                            ");
        $display("****************************************************************************************************\n");
        $display("                ASCII                      Plaintext                             Ciphertext");


        for (int i = 0; your_plaintext.len() != 0 && i < your_plaintext.len()/16+1; i++) begin
            @(posedge clk);
            encrypt <= 1'b1;
            for (int j = 0; j < 16; j++) begin
                plaintext[120-8*j+:8] <= your_plaintext[16*i+j];
            end
            wait(~encrypt_busy);
            @(posedge clk);
            encrypt <= 1'b0;
            wait(encrypt_done);
            @(negedge clk);
            $display("Block %2d: \"%s\"  \"0x%h\"  \"0x%h\"", i, plaintext, plaintext, ciphertext_o);
            ciphertext_q.push_back(ciphertext_o);
        end

        @(posedge clk);
        encrypt <= 1'b0;

        $display("");
        $display("****************************************************************************************************");
        $display("                                            AES decrypt                                            ");
        $display("****************************************************************************************************\n");
        $display("                       Ciphertext                            Plaintext                      ASCII");

        foreach (ciphertext_q[i]) begin
            @(posedge clk);
            decrypt     <= 1'b1;
            ciphertext  <= ciphertext_q[i];
            wait(~decrypt_busy);
            @(posedge clk);
            decrypt <= 1'b0;
            wait(decrypt_done);
            @(negedge clk);
            $display("Block %2d: \"0x%h\"  \"0x%h\"  \"%s\"", i, ciphertext, plaintext_o, plaintext_o);
        end
    endtask

    task set_key_task();
        @(posedge clk);
        set_key <= 1'b1;
        key     <= {$random, $random, $random, $random};
        @(posedge clk);
        set_key <= 1'b0;
        wait(gen_key_done);
        AES_t.get_round_key(key);
    endtask

    task encrypt_task(int ratio = 100);
        assert(tr_encrypt.randomize() with {
            encrypt dist {0:=100-ratio%101, 1:=ratio%101};
        });
        @(posedge clk);
        if (tr_encrypt.encrypt) begin
            encrypt <= 1'b1;
            plaintext <= tr_encrypt.plaintext;
            wait(~encrypt_busy);
            @(posedge clk);
            encrypt <= 1'b0;
            wait (encrypt_done);
            @(negedge clk);
            $display("\n=========== Encrypt =========== time:%0t",$time);
            $display("Key        = 0x%h", key);
            $display("Plaixtext  = 0x%h", tr_encrypt.plaintext);
            $display("Ciphertext = 0x%h", ciphertext_o);
            $write("Golden     = 0x%h", AES_t.encrypt(tr_encrypt.plaintext));
            if (AES_t.encrypt(tr_encrypt.plaintext) === ciphertext_o) $display(" PASS"); else begin $display(" FAIL"); $finish; end
        end
    endtask

    task decrypt_task(int ratio = 100);
        assert(tr_decrypt.randomize() with {
            decrypt dist {0:=100-ratio%101, 1:=ratio%101};
        });
        @(posedge clk);
        if (tr_decrypt.decrypt) begin
            decrypt <= 1'b1;
            ciphertext <= tr_decrypt.ciphertext;
            wait(~decrypt_busy);
            @(posedge clk);
            decrypt <= 1'b0;
            wait(decrypt_done);
            @(negedge clk);

            $display("\n=========== Decrypt =========== time:%0t", $time);
            $display("Key        = 0x%h", key);
            $display("Ciphertext = 0x%h", tr_decrypt.ciphertext);
            $display("Plaixtext  = 0x%h", plaintext_o);
            $write("Golden     = 0x%h", AES_t.decrypt(tr_decrypt.ciphertext));
            if (AES_t.decrypt(tr_decrypt.ciphertext) === plaintext_o) $display(" PASS"); else begin $display(" FAIL"); $finish; end
        end
    endtask

endmodule