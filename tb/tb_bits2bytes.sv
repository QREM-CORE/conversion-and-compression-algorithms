module tb_bits2bytes;

	localparam int N_BYTES = 4;

	logic [N_BYTES*8-1:0] bits_i;
	logic [N_BYTES-1:0][7:0] bytes_o;
	logic [N_BYTES*8-1:0] inc;
	int i;

	bits2bytes #(
		.N_BYTES(N_BYTES)
	) dut (
		.bits_i(bits_i),
		.bytes_o(bytes_o)
	);

	task automatic check_case(logic [N_BYTES*8-1:0] bits, string name);
		logic [N_BYTES-1:0][7:0] exp;
		int i;
		begin
			bits_i = bits;
			for (i = 0; i < N_BYTES; i++) begin
				exp[i] = bits[i*8 +: 8];
			end
			#1; // allow combinational settle
			$display("[bits2bytes %s] bits_i=%h bytes_o=%p exp=%p", name, bits_i, bytes_o, exp);
			if (bytes_o !== exp) begin
				$fatal(1, "bits2bytes %s failed: expected %0h got %0h", name, exp, bytes_o);
			end else begin
				$display("bits2bytes %s passed", name);
			end
		end
	endtask

	initial begin
		// Pattern with mixed bits
		check_case(32'h89_AB_CD_EF, "pattern1");
		// All zeros
		check_case('0, "zeros");
		// All ones
		check_case({N_BYTES*8{1'b1}}, "ones");
		// Incrementing bytes
		for (i = 0; i < N_BYTES; i++) begin
			inc[i*8 +: 8] = i;
		end
		check_case(inc, "incrementing");
		$display("tb_bits2bytes done");
		$finish;
	end

endmodule