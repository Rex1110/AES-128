# AES-128

## 1. Overview

The **[Advanced Encryption Standard (AES)](<https://en.wikipedia.org/wiki/Advanced_Encryption_Standard>)** is a symmetric block cipher established as a U.S. federal standard in 2001, replacing the older DES (Data Encryption Standard). AES is widely used for securing sensitive data in various applications, such as financial transactions, communications, and data storage. It operates on fixed-size blocks of data (128 bits) and supports key sizes of 128, 192, or 256 bits. Its design emphasizes both security and efficiency, making it suitable for hardware and software implementations.

This repository contains an implementation of an AES-128 encryption and decryption system, which uses a 128-bit key and is designed to minimize hardware area. The main modules include:

- **AES**
   - **Key expansion**
      - **G function**
   - **Encryption**
   - **16 x S-BOX**
   - **Decryption**
      - **16 x Inverse S-BOX**

### Brief
1. The first 4 S-BOX are shared between the key expansion and encryption modules to reduce resource usage.  
   - As a result, encryption cannot proceed while the key is being configured.  
2. The key expansion module processes 10 rounds, with one round executed per clock cycle. A finish state is added to ensure decryption does not access round keys that have not yet been fully stored in the registers.  
3. Encryption and decryption operations also process 10 rounds, with one round executed per clock cycle, requiring a total of 10 clock cycles to complete.  
4. Encryption and decryption can be performed simultaneously once the key has been configured.

---

## 2. I/O Interface

| Signal Name         | I/O | Width | Description                                                                 |
|---------------------|-----|-------|-----------------------------------------------------------------------------|
| `clk`               | I   | 1     | Synchronous clock signal, triggered at the **positive edge** of `clk`       |
| `rst_n`             | I   | 1     | Active-low asynchronous reset signal. When asserted (`0`), the system resets |
| `set_key_i`         | I   | 1     | Input signal to trigger key configuration                                   |
| `key_i`             | I   | 128   | The 128-bit encryption/decryption key provided to the system                |
| `encrypt_i`         | I   | 1     | Input signal to start an encryption operation                               |
| `plaintext_i`       | I   | 128   | The plaintext input data to be encrypted                                    |
| `decrypt_i`         | I   | 1     | Input signal to start a decryption operation                                |
| `ciphertext_i`      | I   | 128   | The ciphertext input data to be decrypted                                   |
| `set_key_enable_o`  | O   | 1     | Output signal indicating readiness for key configuration                    |
| `encrypt_busy_o`    | O   | 1     | Indicates that an encryption operation is in progress                       |
| `decrypt_busy_o`    | O   | 1     | Indicates that a decryption operation is in progress                        |
| `gen_key_done_o`    | O   | 1     | Indicates that key configuration is complete                                |
| `encrypt_done_o`    | O   | 1     | Indicates that the encryption operation is complete                         |
| `decrypt_done_o`    | O   | 1     | Indicates that the decryption operation is complete                         |
| `plaintext_o`       | O   | 128   | The plaintext output data after decryption                                  |
| `ciphertext_o`      | O   | 128   | The ciphertext output data after encryption                                 |

---

## 3. State machine in each module

### 1. Key expansion module
![key_expansion module](https://github.com/user-attachments/assets/1bacd90f-5e14-477a-a29f-dd0c28ef3763)
---

### 2. AES encrypt module
![AES_encrypt module](https://github.com/user-attachments/assets/62559a32-99f9-485a-a517-bcccd58d870f)
---

### 3. AES decrypt module
![AES_decrypt module](https://github.com/user-attachments/assets/ca62f537-62bd-4f78-866a-ea3ddede3ac2)
---

## 4. Testbench and assertions

### 1. Testbench features

The testbench is designed to verify the functionality of the AES-128 implementation, supporting both directed and constrained random testing:

- Directed testing:
   - Users can manually configure plaintext and key inputs to directly verify the expected functionality of encryption and decryption.

- Constrained random verification:
   - The testbench allows users to apply constraints to randomly generate combinations of plaintext and key.  
   - Additionally, it enables control over the frequency and concurrency of encryption and decryption operations to simulate various scenarios and edge cases.

---

### 2. Assertions in design

To ensure proper system behavior during the key expansion process, assertions are added to verify that both encryption and decryption modules remain in their respective IDLE states.

#### Assertions description
1. Ensures that the encryption module remains in the IDLE state during key expansion:
```systemverilog
when_key_expansion_encrypt_idle: assert property (
@(posedge clk) disable iff (~rst_n) (
   (key_expansion_.state !== 4'd0) |-> (AES_encrypt_.state === 4'd0)
   )
);
```
2. Ensures that the decryption module remains in the IDLE state during key expansion:
```systemverilog
when_key_expansion_decrypt_idle: assert property (
    @(posedge clk) disable iff (~rst_n) (
        (key_expansion_.state !== 4'd0) |-> (AES_decrypt_.state === 4'd10)
    )
);
```

## 5. Encrypt && decrypt example
### Plaintext:
This AES-128 system is designed to minimize area, featuring modules for Key Expansion, Encrypt, Decrypt, 16 S-box, and 16 Inverse S-box. To optimize resources, the first 4 S-boxes are shared between the Key Expansion and Encrypt modules. The key schedule requires 10 rounds of computation and includes a finish state to prevent decryption from using incomplete round keys. Each encryption or decryption operation takes 10 clock cycles, and key reconfiguration can only occur after current operations are fully completed.
### Key:
0x54686174_7320756e_67204675_6d79204b

---

![encrypt](https://github.com/user-attachments/assets/4b582e82-d2f2-40b1-89e3-8dde8be2ab78)


![decrypt](https://github.com/user-attachments/assets/cedfce22-dc4e-435e-baa1-c25bbd972e94)

## 6. Waveform

### 1. Set key

In the first clock cycle, the `set_key_i` signal is asserted, and the key is written into the key0 register. Subsequently, a key expansion operation is performed in each clock cycle, and the computed results are sequentially stored into the corresponding key registers. Once the key10 register is written, the `gen_key_done` signal is asserted to indicate the completion of the key expansion process.

![set_key](https://github.com/user-attachments/assets/30bd9836-5132-4adf-8f88-8032c8418afd)


### 2. Encrypt and decrypt

When encryption is allowed (i.e., not during the key generation process), the `encrypt` signal is asserted to initiate the operation. The process begins with the initial round key addition in the first clock cycle. This is followed by nine rounds of operations, where each round sequentially performs `SubBytes`, `ShiftRows`, `MixColumns`, and `AddRoundKey`. Finally, the encryption concludes with a final round that performs `SubBytes`, `ShiftRows`, and `AddRoundKey`, excluding the `MixColumns` operation. Once the encryption process is complete, the `encrypt_done` signal is asserted to indicate its completion.

Similarly, when decryption is allowed, the `decrypt` signal is asserted to initiate the operation. The process starts with the initial round key addition in the first clock cycle. This is followed by nine rounds of operations, where each round sequentially performs `InvShiftRows`, `InvSubBytes`, `AddRoundKey`, and `InvMixColumns`. Finally, the decryption concludes with a final round that performs `InvShiftRows`, `InvSubBytes`, and `AddRoundKey`, excluding the `InvMixColumns` operation. Once the decryption process is complete, the `decrypt_done` signal is asserted to indicate its completion.

![en_de](https://github.com/user-attachments/assets/32d2cb3e-0bb4-4d47-8bb5-7533a0a507c5)

