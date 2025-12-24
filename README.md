# conversion-and-compression-algorithms

![Language](https://img.shields.io/badge/Language-SystemVerilog-blue)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

SystemVerilog helpers for turning ML-KEM (Kyber-style) coefficient streams into bytes and back. The blocks are tiny, combinational, and parameterized so you can drop them into FPGA or ASIC flows without extra plumbing.

## What each module does

- [rtl/bits2bytes.sv](rtl/bits2bytes.sv): Takes a flat bit vector and groups it into bytes. Bit 0 of the input becomes bit 0 of byte 0 (little-endian per byte).
- [rtl/bytes2bits.sv](rtl/bytes2bits.sv): The inverse of `bits2bytes`; spreads a byte array back into a flat bit vector.
- [rtl/byte_encode.sv](rtl/byte_encode.sv): Implements Algorithm 5 (ByteEncode_d). Packs 256 integers, each `D` bits wide, into `32*D` bytes.
- [rtl/byte_decode.sv](rtl/byte_decode.sv): Implements Algorithm 6 (ByteDecode_d). Unpacks `32*D` bytes back into 256 integers and applies the expected modulus.
- [tb](tb): Empty stubs so you can wire up your own stimulus quickly.

## Data ordering in plain words

- Inside each byte, bit 0 is the least significant bit of the coefficient.
- Coefficients are packed consecutively: coefficient 0 consumes bits 0..D-1, coefficient 1 consumes bits D..2D-1, and so on.
- For `byte_decode` when `D=12`, values are reduced mod 3329 (Kyber q). For other `D`, modulus is `2^D`.

## Module details (parameters and ports)

### bits2bytes
- Parameter: `N_BYTES` (default 1) sets input width to `8*N_BYTES` bits and output to `N_BYTES` bytes.
- Ports: `bits_i` flat vector in, `bytes_o` array out.

### bytes2bits
- Parameter: `N_BYTES` (default 1) sets input width to `N_BYTES` bytes and output to `8*N_BYTES` bits.
- Ports: `bytes_i` array in, `bits_o` flat vector out.

### byte_encode
- Parameters: `D` (1–12), `IN_WIDTH` (>= D, default 16).
- Ports: `f_i` is 256 integers wide (`IN_WIDTH` each); `b_o` is `32*D` bytes.
- Behavior: Copies each coefficient into a packed bitstream, little-endian within each coefficient, then calls `bits2bytes` to group into bytes.

### byte_decode
- Parameters: `D` (1–12), `OUT_WIDTH` (defaults to `D`, or 12 when `D=12`).
- Ports: `b_i` is `32*D` bytes; `f_o` is 256 integers (`OUT_WIDTH` each).
- Behavior: Uses `bytes2bits` to flatten, rebuilds each coefficient, then applies modulus (3329 when `D=12`, else `2^D`).

## Quick-start example

Packing and unpacking 256 twelve-bit coefficients (Kyber case):

```systemverilog
localparam int D = 12;

logic [255:0][15:0] coeffs_in;   // width >= D
logic [32*D-1:0][7:0] packed;
logic [255:0][11:0] coeffs_out;

byte_encode #(
	.D(D),
	.IN_WIDTH(16)
) u_encode (
	.f_i(coeffs_in),
	.b_o(packed)
);

byte_decode #(
	.D(D)
) u_decode (
	.b_i(packed),
	.f_o(coeffs_out)
);
```

Because everything is combinational, a single-cycle smoke test (drive inputs, wait a delta cycle, check outputs) is usually enough.

## Parameter tips

- `D` must be 1–12; each module has a guard that errors out in simulation if violated.
- Set `IN_WIDTH` to at least `D`; keeping a few spare bits (like 16) is common when upstream logic already uses wider buses.
- Keep `OUT_WIDTH` aligned with the rest of your datapath; leave it at the default 12 for Kyber.

## Simulating

- Drop your own stimulus into the testbench shells in [tb](tb). No clocks are required unless you add pipelining around these blocks.
- For self-checking tests, instantiate `byte_encode` feeding `byte_decode` and confirm round-trip equality (allowing for the modulus behavior when `D=12`).

## Repository layout

- `rtl/`: Core converters and ML-KEM byte encode/decode helpers.
- `tb/`: Testbench shells you can extend.
- `env.sh`: Optional environment setup hook.

## License

See [LICENSE](LICENSE).