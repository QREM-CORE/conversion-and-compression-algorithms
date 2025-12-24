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

	// DUT instances.
	byte_encode #(.D(D1), .IN_WIDTH(INW)) dut1 (.f_i(f1), .b_o(b1));
	byte_encode #(.D(D2), .IN_WIDTH(INW)) dut2 (.f_i(f2), .b_o(b2));
	byte_encode #(.D(D3), .IN_WIDTH(INW)) dut3 (.f_i(f3), .b_o(b3));

	// Helper to compute expected bytes for a given d and input array.
	task automatic compute_expected(
		input  int d,
		input  logic [255:0][INW-1:0] f,
		output logic [32*d-1:0][7:0] b
	);
		int i, j;
		logic [256*d-1:0] bits;
		begin
			bits = '0;
			for (i = 0; i < 256; i++) begin
				int unsigned a;
				a = f[i];
				for (j = 0; j < d; j++) begin
					bits[i*d + j] = a[0];
					a = a >> 1;
				end
			end
			for (i = 0; i < 32*d; i++) begin
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

	task automatic run_and_check;
		begin
			compute_expected(D1, f1, exp_b1);
			compute_expected(D2, f2, exp_b2);
			compute_expected(D3, f3, exp_b3);

			#1;

			if (b1 !== exp_b1) $fatal(1, "encode d=1 mismatch");
			if (b2 !== exp_b2) $fatal(1, "encode d=8 mismatch");
			if (b3 !== exp_b3) $fatal(1, "encode d=12 mismatch");

			$display("tb_byte_encode passed for d=1,8,12");
		end
	endtask

	initial begin
		init_inputs();
		run_and_check();
		$finish;
	end

endmodule