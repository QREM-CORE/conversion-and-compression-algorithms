// Converts a flat bit vector (little-endian within each byte) into an array of bytes.
module bits2bytes #(
	parameter int N_BYTES = 1  // number of output bytes; input width is 8*N_BYTES
)(
	input  logic [N_BYTES*8-1:0] bits_i,
	output logic [N_BYTES-1:0][7:0] bytes_o
);

	integer i;

	always_comb begin
		bytes_o = '0;
		for (i = 0; i < N_BYTES; i++) begin
			// Slice keeps bit 0 of bits_i as bit 0 of the byte (little-endian per algorithm).
			bytes_o[i] = bits_i[i*8 +: 8];
		end
	end

endmodule