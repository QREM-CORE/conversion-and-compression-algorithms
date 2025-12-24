module tb_byte_encode;

	// Test three representative d values.
	localparam int D1 = 1;
	localparam int D2 = 8;
	localparam int D3 = 12;

	// IN_WIDTH chosen to cover d=12 path (needs q=3329 < 2^12, still fits in 16 bits).
	localparam int INW = 16;

	// Stimulus arrays.
	logic [255:0][INW-1:0] f1, f2, f3;

	// DUT outputs.
	logic [32*D1-1:0][7:0] b1;
	logic [32*D2-1:0][7:0] b2;
	logic [32*D3-1:0][7:0] b3;

	// Expected.
	logic [32*D1-1:0][7:0] exp_b1;
	logic [32*D2-1:0][7:0] exp_b2;
	logic [32*D3-1:0][7:0] exp_b3;

	int pass_cnt;
	int test_cnt;
	int unsigned seed = 32'h1ce1_ce01;

	// DUT instances.
	byte_encode #(.D(D1), .IN_WIDTH(INW)) dut1 (.f_i(f1), .b_o(b1));
	byte_encode #(.D(D2), .IN_WIDTH(INW)) dut2 (.f_i(f2), .b_o(b2));
	byte_encode #(.D(D3), .IN_WIDTH(INW)) dut3 (.f_i(f3), .b_o(b3));

	// Helpers to compute expected bytes for fixed d values (avoids non-constant ranges).
	task automatic compute_expected_d1(
		input  logic [255:0][INW-1:0] f,
		output logic [32*D1-1:0][7:0] b
	);
		int i, j;
		logic [256*D1-1:0] bits;
		begin
			bits = '0;
			for (i = 0; i < 256; i++) begin
				int unsigned a;
				a = f[i];
				for (j = 0; j < D1; j++) begin
					bits[i*D1 + j] = a[0];
					a = a >> 1;
				end
			end
			for (i = 0; i < 32*D1; i++) begin
				b[i] = bits[i*8 +: 8];
			end
		end
	endtask

	task automatic compute_expected_d2(
		input  logic [255:0][INW-1:0] f,
		output logic [32*D2-1:0][7:0] b
	);
		int i, j;
		logic [256*D2-1:0] bits;
		begin
			bits = '0;
			for (i = 0; i < 256; i++) begin
				int unsigned a;
				a = f[i];
				for (j = 0; j < D2; j++) begin
					bits[i*D2 + j] = a[0];
					a = a >> 1;
				end
			end
			for (i = 0; i < 32*D2; i++) begin
				b[i] = bits[i*8 +: 8];
			end
		end
	endtask

	task automatic compute_expected_d3(
		input  logic [255:0][INW-1:0] f,
		output logic [32*D3-1:0][7:0] b
	);
		int i, j;
		logic [256*D3-1:0] bits;
		begin
			bits = '0;
			for (i = 0; i < 256; i++) begin
				int unsigned a;
				a = f[i];
				for (j = 0; j < D3; j++) begin
					bits[i*D3 + j] = a[0];
					a = a >> 1;
				end
			end
			for (i = 0; i < 32*D3; i++) begin
				b[i] = bits[i*8 +: 8];
			end
		end
	endtask

	// Load deterministic stimuli.
	task automatic init_inputs;
		int i;
		begin
			for (i = 0; i < 256; i++) begin
				f1[i] = i % (1 << D1);
				f2[i] = i % (1 << D2);
				f3[i] = i % 3329; // modulus q for d=12
			end
		end
	endtask

	task automatic randomize_inputs;
		int i;
		begin
			for (i = 0; i < 256; i++) begin
				f1[i] = $urandom(seed) & ((1 << D1) - 1);
				f2[i] = $urandom(seed + 1) & 8'hFF;
				f3[i] = $urandom(seed + 2) % 3329;
				seed = seed + 32'h9e37;
			end
		end
	endtask

	task automatic run_and_check(string label);
		begin
			compute_expected_d1(f1, exp_b1);
			compute_expected_d2(f2, exp_b2);
			compute_expected_d3(f3, exp_b3);

			#1;

			$display("[byte_encode][%s][d=1] f0-3=%p b0-7=%p", label, f1[0 +: 4], b1[0 +: 8]);
			$display("[byte_encode][%s][d=8] f0-3=%p b0-7=%p", label, f2[0 +: 4], b2[0 +: 8]);
			$display("[byte_encode][%s][d=12] f0-3=%p b0-7=%p", label, f3[0 +: 4], b3[0 +: 8]);

			if (b1 !== exp_b1) $fatal(1, "encode %s d=1 mismatch", label);
			if (b2 !== exp_b2) $fatal(1, "encode %s d=8 mismatch", label);
			if (b3 !== exp_b3) $fatal(1, "encode %s d=12 mismatch", label);

			pass_cnt++;
			test_cnt++;
		end
	endtask

	initial begin
		pass_cnt = 0;
		test_cnt = 0;

		init_inputs();
		run_and_check("directed");

		// Randomized trials
		repeat (3) begin
			randomize_inputs();
			run_and_check("random");
		end

		$display("[byte_encode] Summary: %0d/%0d PASS", pass_cnt, test_cnt);
		$finish;
	end

endmodule