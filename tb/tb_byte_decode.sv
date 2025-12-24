module tb_byte_decode;

	// Test three representative d values.
	localparam int D1 = 1;
	localparam int D2 = 8;
	localparam int D3 = 12;
	localparam int INW = 16;

	// Stimulus integers.
	logic [255:0][INW-1:0] f1, f2, f3;

	// Encoded bytes produced by the encode DUTs (guarantees identical packing).
	logic [32*D1-1:0][7:0] b1;
	logic [32*D2-1:0][7:0] b2;
	logic [32*D3-1:0][7:0] b3;

	// Decode outputs.
	logic [255:0][D1-1:0]        f1_o;
	logic [255:0][D2-1:0]        f2_o;
	logic [255:0][11:0]          f3_o; // OUT_WIDTH is 12 when d=12

	int pass_cnt;
	int test_cnt;
	int unsigned seed = 32'hd00d_dec0;

	// Encode + Decode DUTs per d value (encode drives byte arrays).
	byte_encode #(.D(D1), .IN_WIDTH(INW)) enc1 (.f_i(f1), .b_o(b1));
	byte_encode #(.D(D2), .IN_WIDTH(INW)) enc2 (.f_i(f2), .b_o(b2));
	byte_encode #(.D(D3), .IN_WIDTH(INW)) enc3 (.f_i(f3), .b_o(b3));

	byte_decode #(.D(D1)) dut1 (.b_i(b1), .f_o(f1_o));
	byte_decode #(.D(D2)) dut2 (.b_i(b2), .f_o(f2_o));
	byte_decode #(.D(D3)) dut3 (.b_i(b3), .f_o(f3_o));

	task automatic init_inputs;
		int i;
		begin
			for (i = 0; i < 256; i++) begin
				f1[i] = i % (1 << D1);
				f2[i] = i % (1 << D2);
				f3[i] = i % 3329;
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
				seed = seed + 32'h5a5a;
			end
		end
	endtask

	task automatic run_and_check(string label);
		int i;
		begin
			#1;
			$display("[byte_decode][%s][d=1] b0-7=%p f_in0-3=%p f_out0-3=%p", label, b1[0 +: 8], f1[0 +: 4], f1_o[0 +: 4]);
			$display("[byte_decode][%s][d=8] b0-7=%p f_in0-3=%p f_out0-3=%p", label, b2[0 +: 8], f2[0 +: 4], f2_o[0 +: 4]);
			$display("[byte_decode][%s][d=12] b0-7=%p f_in0-3=%p f_out0-3=%p", label, b3[0 +: 8], f3[0 +: 4], f3_o[0 +: 4]);
			for (i = 0; i < 256; i++) begin
				if (f1_o[i] !== f1[i][D1-1:0]) $fatal(1, "decode d=1 mismatch at %0d", i);
				if (f2_o[i] !== f2[i][D2-1:0]) $fatal(1, "decode d=8 mismatch at %0d", i);
				if (f3_o[i] !== f3[i][11:0])    $fatal(1, "decode d=12 mismatch at %0d", i);
			end
			$display("[byte_decode][%s] PASS", label);
			pass_cnt++;
			test_cnt++;
		end
	endtask

	initial begin
		pass_cnt = 0;
		test_cnt = 0;

		init_inputs();
		run_and_check("directed");

		repeat (3) begin
			randomize_inputs();
			run_and_check("random");
		end

		$display("[byte_decode] Summary: %0d/%0d PASS", pass_cnt, test_cnt);
		$finish;
	end

endmodule