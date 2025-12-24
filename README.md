# conversion-and-compression-algorithms

![Language](https://img.shields.io/badge/Language-SystemVerilog-blue)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

SystemVerilog helpers for turning ML-KEM (Kyber-style) coefficient streams into bytes and back. The blocks are tiny, combinational, and parameterized so you can drop them into FPGA or ASIC flows without extra plumbing.

## Highlights

- ML-KEM (Kyber) oriented helpers: ByteEncode_d, ByteDecode_d, and generic bit/byte packers.
- Purely combinational RTL: no clocks or resets; drop-in friendly.
- Parameterized widths: tune `D`, `IN_WIDTH`, `OUT_WIDTH`, and `N_BYTES` to fit your datapath.
- Endianness defined: bit 0 of a coefficient is bit 0 of byte 0 (little-endian within each byte).

## What each module does

- [rtl/bits2bytes.sv](rtl/bits2bytes.sv): Flat bit vector → byte array (LSB-first inside each byte).
- [rtl/bytes2bits.sv](rtl/bytes2bits.sv): Byte array → flat bit vector (inverse of `bits2bytes`).
- [rtl/byte_encode.sv](rtl/byte_encode.sv): Algorithm 5 (ByteEncode_d). Packs 256 integers of width `D` into `32*D` bytes.
- [rtl/byte_decode.sv](rtl/byte_decode.sv): Algorithm 6 (ByteDecode_d). Unpacks `32*D` bytes into 256 integers and applies the modulus.
- [tb](tb): Ready-made self-checking benches for each module.

## Data ordering in plain words

- Bit 0 of a coefficient is the LSB and is emitted first.
- Coefficients pack back-to-back: coeff 0 uses bits 0..D-1, coeff 1 uses bits D..2D-1, etc.
- Decode modulus: if `D=12`, values reduce mod 3329 (Kyber q); otherwise modulus is `2^D`.

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
- Behavior: Packs each coefficient LSB-first into a bitstream, then groups into bytes via `bits2bytes`.

### byte_decode
- Parameters: `D` (1–12), `OUT_WIDTH` (defaults to `D`, or 12 when `D=12`).
- Ports: `b_i` is `32*D` bytes; `f_o` is 256 integers (`OUT_WIDTH` each).
- Behavior: Flattens bytes with `bytes2bits`, rebuilds coefficients LSB-first, then applies the modulus rule above.

## Quick parameter reference

- `D`: Coefficient bit-width (1–12). Use 12 for Kyber q=3329.
- `IN_WIDTH`: Input coefficient width into `byte_encode`; must be >= `D` (16 is common).
- `OUT_WIDTH`: Output width from `byte_decode`; defaults to `D` (12 when `D=12`).
- `N_BYTES`: Number of bytes when using the generic packers (`bits2bytes`/`bytes2bits`).

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

## Integration tips

- Guards: `D` must be 1–12; assertions fire in simulation if violated.
- Widths: Set `IN_WIDTH` ≥ `D`; leave `OUT_WIDTH` at the default unless your downstream path is narrower/wider.
- Timing: RTL is combinational; add registers around the boundary if you need to meet timing.
- Endianness: Bit ordering is fixed LSB-first; no byte swapping needed.

## Testing

- Included benches:
	- [tb/tb_bits2bytes.sv](tb/tb_bits2bytes.sv): Directed + random checks for the packer.
	- [tb/tb_bytes2bits.sv](tb/tb_bytes2bits.sv): Directed + random checks for the unpacker.
	- [tb/tb_byte_encode.sv](tb/tb_byte_encode.sv): Tests `D` = 1, 8, 12 with directed/random stimuli and local golden models.
	- [tb/tb_byte_decode.sv](tb/tb_byte_decode.sv): Encode→decode round-trip for `D` = 1, 8, 12; verifies modulo handling.

- Run with ModelSim/Questa via the provided [Makefile](Makefile):
	- `make` or `make run_all` — build `work` and run all benches.
	- `make run_tb_bits2bytes` (or any listed target) — compile RTL + that bench and run it.
	- `make clean` — remove `work` and temporary artifacts.

Override tools with `VLOG=`, `VSIM=`, `VLIB=`, and change library name with `WORK=` if needed.

## Repository layout

- `rtl/`: Core converters and ML-KEM byte encode/decode helpers.
- `tb/`: Testbench shells you can extend.
- `env.sh`: Optional environment setup hook.

## License

See [LICENSE](LICENSE).