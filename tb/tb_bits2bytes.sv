module tb_bits2bytes;

	localparam int N_BYTES = 4;

	logic [N_BYTES*8-1:0] bits_i;
	logic [N_BYTES-1:0][7:0] bytes_o;
	logic [N_BYTES*8-1:0] inc;
	int i;
	int pass_cnt;
	int test_cnt;
	int unsigned seed = 32'hb17b_2b17;

	bits2bytes #(
		.N_BYTES(N_BYTES)
	) dut (
		.bits_i(bits_i),
		.bytes_o(bytes_o)
	);

	task automatic check_case(logic [N_BYTES*8-1:0] bits, string name);
		logic [N_BYTES-1:0][7:0] exp;
		int j;
		begin
			bits_i = bits;
			for (j = 0; j < N_BYTES; j++) begin
				exp[j] = bits[j*8 +: 8];
			end
			#1; // allow combinational settle
			$display("[bits2bytes][%s] bits=%h bytes=%p", name, bits_i, bytes_o);
			if (bytes_o !== exp) begin
				$fatal(1, "bits2bytes %s failed: expected %0h got %0h", name, exp, bytes_o);
			end else begin
				$display("[bits2bytes][%s] PASS", name);
				pass_cnt++;
			end
			test_cnt++;
		end
	endtask

	initial begin
		pass_cnt = 0;
		test_cnt = 0;

		// Directed patterns
		check_case(32'h89_AB_CD_EF, "pattern1");
		check_case('0, "zeros");
		check_case({N_BYTES*8{1'b1}}, "ones");
		for (i = 0; i < N_BYTES; i++) begin
			inc[i*8 +: 8] = i;
		end
		check_case(inc, "incrementing");

		// Randomized patterns
		for (i = 0; i < 5; i++) begin
			bits_i = $urandom(seed);
			seed   = seed + 32'h1021;
			check_case(bits_i, $sformatf("random%0d", i));
		end

		$display("[bits2bytes] Summary: %0d/%0d PASS", pass_cnt, test_cnt);
		$finish;
	end

endmodule