// SPDX-License-Identifier: BSD-2-Clause

module simple_filterbank (
	input wire clk,
	input wire rst,
	input wire signed [15:0] sample,
	input wire sample_valid,
	output wire signed [15:0] windowed_sample_output,
	output wire wso_valid

);

wire [3:0] sample_block_offset;
reg [8:0] sample_idx = 9'd0;
assign sample_block_offset = sample_idx[8:5];

reg signed [15:0] sample_ebr [0:511];
reg signed [15:0] filter_coef [0:511];
reg signed [15:0] windowed_ebr [0:63];
reg [3:0] read_offset_msb = 4'd0;
reg [4:0] read_offset_lsb = 5'd0;
wire [8:0] read_sample_offset = {read_offset_msb, read_offset_lsb};
reg signed [15:0] read_sample = 16'd0;
reg signed [15:0] read_coef = 16'd0;
reg [8:0] coef_idx = 9'd0;
reg filtering = 1'b0;
reg filtering_r1 = 1'b0;
reg filtering_r2 = 1'b0;
reg signed [31:0] windowed_sample = 32'd0;
reg signed [31:0] sum_windowed_sample = 32'd0;
reg [5:0] windowed_idx = 6'd0;
reg y_sum = 1'b0;
reg y_sum_r1 = 1'b0;
reg y_sum_r2 = 1'b0;
reg y_sum_r3 = 1'b0;

assign windowed_sample_output = windowed_sample[30:15];
assign wso_valid = filtering_r2;

initial begin
$readmemh("zero.mem", sample_ebr);
end

initial begin
$readmemh("filter_coef.mem", filter_coef);
end

always @(posedge clk) begin
	filtering_r1 <= filtering;
	filtering_r2 <= filtering_r1;
	y_sum <= sample_valid | do_old_block;
	y_sum_r1 <= y_sum;
	y_sum_r2 <= y_sum_r1;
	y_sum_r3 <= y_sum_r2;
	if (sample_valid) begin
		sample_ebr[sample_idx] <= sample;
		sample_idx <= sample_idx + 9'd1;
		if (sample_idx[4:0] == 5'h00) begin
			read_offset_msb[0] <= sample_block_offset[5];
		end
	end
	if (y_sum) begin
		y_sum <= 1'b1;
		read_offset_msb <= read_offset_msb + 4'd2;
		coef_idx <= coef_idx + 9'd64;
		read_sample <= sample_ebr[read_sample_offset];
		read_coef <= filter_coef[coef_idx];
		if (read_offset_msb[8:6] == 3'b111) begin
			y_sum <= 1'b0;
			read_offset_msb[0] <= ~read_offset_msb[0];
			do_old_block <= 1'b0;
			if (do_old_block) begin
				if (read_offset_msb[0] != sample_block_offset[5]) begin
					filtering <= 1'b1;
				end
			end else begin
				do_old_block <= 1'b1;
			end
		end
	end
	if (y_sum_r1) begin
		windowed_sample <= read_sample * read_coef;
	end
	if (y_sum_r2) begin
		sum_windowed_sample <= sum_windowed_sample + windowed_sample;
	end else begin
		sum_windowed_sample <= 32'd0;
		if (y_sum_r3) begin
			windowed_idx <= windowed_idx + 9'd1;
			windowed_ebr[windowed_idx] <= sum_windowed_sample[30:15];
		end
	end
	if (filtering_r1) begin
	end
	if (filtering_r2) begin
	end
end

always @(posedge clk) begin
end

endmodule
