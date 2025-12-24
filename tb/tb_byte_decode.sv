module tb_byte_decode;

	// Test three representative d values.
	localparam int D1 = 1;
	localparam int D2 = 8;
	localparam int D3 = 12;
	localparam int INW = 16;

	// Stimulus integers (these mirror the encode TB inputs).
	logic [255:0][INW-1:0] f1, f2, f3;

	// Byte arrays to feed decode.
	logic [32*D1-1:0][7:0] b1;
	logic [32*D2-1:0][7:0] b2;
	logic [32*D3-1:0][7:0] b3;

	// Decode outputs.
	logic [255:0][D1-1:0]        f1_o;
	logic [255:0][D2-1:0]        f2_o;
	logic [255:0][11:0]          f3_o; // OUT_WIDTH is 12 when d=12

	// DUTs.
	byte_decode #(.D(D1)) dut1 (.b_i(b1), .f_o(f1_o));
	byte_decode #(.D(D2)) dut2 (.b_i(b2), .f_o(f2_o));
	byte_decode #(.D(D3)) dut3 (.b_i(b3), .f_o(f3_o));

	// Helper to create byte arrays from integers (same packing as encode).
	task automatic pack_bytes(
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

	task automatic init_inputs;
		int i;
		begin
			for (i = 0; i < 256; i++) begin
				f1[i] = i % (1 << D1);
				f2[i] = i % (1 << D2);
				f3[i] = i % 3329;
			end
			pack_bytes(D1, f1, b1);
			pack_bytes(D2, f2, b2);
			pack_bytes(D3, f3, b3);
		end
	endtask

	task automatic run_and_check;
		int i;
		begin
			#1;
			for (i = 0; i < 256; i++) begin
				if (f1_o[i] !== f1[i][D1-1:0]) $fatal(1, "decode d=1 mismatch at %0d", i);
				if (f2_o[i] !== f2[i][D2-1:0]) $fatal(1, "decode d=8 mismatch at %0d", i);
				if (f3_o[i] !== f3[i][11:0])    $fatal(1, "decode d=12 mismatch at %0d", i);
			end
			$display("tb_byte_decode passed for d=1,8,12");
		end
	endtask

	initial begin
		init_inputs();
		run_and_check();
		$finish;
	end

endmodule