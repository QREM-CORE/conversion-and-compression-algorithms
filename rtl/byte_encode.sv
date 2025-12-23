// Implements Algorithm 5 (ByteEncode_d) from the spec.
// Converts 256 integers (width >= d) into 32*d bytes using little-endian bit packing.
module byte_encode #(
	parameter int D = 12,             // 1 <= D <= 12
	parameter int IN_WIDTH = 16       // must be >= D; wide enough to hold q when D=12
)(
	input  logic [255:0][IN_WIDTH-1:0] f_i,
	output logic [32*D-1:0][7:0]       b_o
);

	localparam int TOTAL_BITS  = 256 * D;
	localparam int TOTAL_BYTES = TOTAL_BITS / 8; // 256 is divisible by 8

	logic [TOTAL_BITS-1:0] b_bits;
	logic [TOTAL_BYTES-1:0][7:0] b_bytes;

	integer i;
	integer j;

	// Build the packed bit array, then hand off to bits2bytes for grouping into bytes.
	always_comb begin
		b_bits = '0;
		for (i = 0; i < 256; i++) begin
			int unsigned a;
			a = f_i[i];
			for (j = 0; j < D; j++) begin
				b_bits[i*D + j] = a[0];
				a = a >> 1; // (a - bit) / 2 in the pseudocode
			end
		end
	end

	// Reuse the generic converter to map packed bits into bytes.
	bits2bytes #(
		.N_BYTES(TOTAL_BYTES)
	) bits2bytes_i (
		.bits_i (b_bits),
		.bytes_o(b_bytes)
	);

	assign b_o = b_bytes;

	// Simple parameter guard to catch accidental misuse.
	initial begin
		if (D < 1 || D > 12) begin
			$error("byte_encode: parameter D must be in the range 1..12 (got %0d)", D);
		end
	end

endmodule