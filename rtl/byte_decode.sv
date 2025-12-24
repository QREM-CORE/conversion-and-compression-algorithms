// Implements Algorithm 6 (ByteDecode_d) from the spec.
// Converts 32*d input bytes back into 256 integers using little-endian bit unpacking.
module byte_decode #(
	parameter int D = 12,                       // 1 <= D <= 12
	parameter int OUT_WIDTH = (D == 12) ? 12 : D // width of each output integer
)(
	input  wire  logic [32*D-1:0][7:0] b_i,
	output logic [255:0][OUT_WIDTH-1:0] f_o
);

	localparam int TOTAL_BITS  = 256 * D;
	localparam int TOTAL_BYTES = TOTAL_BITS / 8;
	localparam int MOD = (D == 12) ? 3329 : (1 << D);

	logic [TOTAL_BITS-1:0] b_bits;

	integer i;
	integer j;

	// Convert incoming bytes to a flat bit vector, then recover each integer.
	always_comb begin
		for (i = 0; i < 256; i++) begin
			int unsigned acc;
			acc = 0;
			for (j = 0; j < D; j++) begin
				if (b_bits[i*D + j]) begin
					acc += (1 << j);
				end
			end
			acc = acc % MOD;
			f_o[i] = acc[OUT_WIDTH-1:0];
		end
	end

	// Reuse generic converter to flatten the byte array into bits.
	bytes2bits #(
		.N_BYTES(TOTAL_BYTES)
	) bytes2bits_i (
		.bytes_i(b_i),
		.bits_o (b_bits)
	);

	initial begin
		if (D < 1 || D > 12) begin
			$error("byte_decode: parameter D must be in the range 1..12 (got %0d)", D);
		end
	end

endmodule