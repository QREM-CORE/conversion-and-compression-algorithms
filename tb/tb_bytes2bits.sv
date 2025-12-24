module tb_bytes2bits;

	localparam int N_BYTES = 4;

	logic [N_BYTES-1:0][7:0] bytes_i;
	logic [N_BYTES*8-1:0] bits_o;
	logic [N_BYTES-1:0][7:0] pat;
	int i;
	int pass_cnt;
	int test_cnt;
	int unsigned seed = 32'hb17b_2b17;

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
			$display("[bytes2bits][%s] bytes=%p bits=%h", name, bytes_i, bits_o);
			if (bits_o !== exp) begin
				$fatal(1, "bytes2bits %s failed: expected %0h got %0h", name, exp, bits_o);
			end else begin
				$display("[bytes2bits][%s] PASS", name);
				pass_cnt++;
			end
			test_cnt++;
		end
	endtask

	initial begin
		pass_cnt = 0;
		test_cnt = 0;

		// Directed patterns
		pat[0] = 8'hEF;
		pat[1] = 8'hCD;
		pat[2] = 8'hAB;
		pat[3] = 8'h89;
		check_case(pat, "pattern1");

		pat = '0;
		check_case(pat, "zeros");

		pat = {N_BYTES{8'hFF}};
		check_case(pat, "ones");

		for (i = 0; i < N_BYTES; i++) begin
			pat[i] = i;
		end
		check_case(pat, "incrementing");

		// Randomized patterns
		for (i = 0; i < 5; i++) begin
			pat = $urandom(seed);
			seed = seed + 32'h2041;
			check_case(pat, $sformatf("random%0d", i));
		end

		$display("[bytes2bits] Summary: %0d/%0d PASS", pass_cnt, test_cnt);
		$finish;
	end

endmodule