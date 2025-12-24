module tb_bytes2bits;

	localparam int N_BYTES = 4;

	logic [N_BYTES-1:0][7:0] bytes_i;
	logic [N_BYTES*8-1:0] bits_o;
	logic [N_BYTES-1:0][7:0] pat;
	int i;

	bytes2bits #(
		.N_BYTES(N_BYTES)
	) dut (
		.bytes_i(bytes_i),
		.bits_o(bits_o)
	);

	task automatic check_case(logic [N_BYTES-1:0][7:0] bytes, string name);
		logic [N_BYTES*8-1:0] exp;
		int i;
		begin
			bytes_i = bytes;
			for (i = 0; i < N_BYTES; i++) begin
				exp[i*8 +: 8] = bytes[i];
			end
			#1;
			$display("[bytes2bits %s] bytes_i=%p bits_o=%h exp=%h", name, bytes_i, bits_o, exp);
			if (bits_o !== exp) begin
				$fatal(1, "bytes2bits %s failed: expected %0h got %0h", name, exp, bits_o);
			end else begin
				$display("bytes2bits %s passed", name);
			end
		end
	endtask

	initial begin
		// Pattern with specific bytes
		pat[0] = 8'hEF;
		pat[1] = 8'hCD;
		pat[2] = 8'hAB;
		pat[3] = 8'h89;
		check_case(pat, "pattern1");

		// All zeros
		pat = '0;
		check_case(pat, "zeros");

		// All ones
		pat = {N_BYTES{8'hFF}};
		check_case(pat, "ones");

		// Incrementing bytes
		for (i = 0; i < N_BYTES; i++) begin
			pat[i] = i;
		end
		check_case(pat, "incrementing");

		$display("tb_bytes2bits done");
		$finish;
	end

endmodule