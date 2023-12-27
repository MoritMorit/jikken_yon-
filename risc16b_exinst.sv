`default_nettype none

  module risc16b
    (
     input wire 	 clk,
     input wire 	 rst,
     output logic [15:0] i_addr,
     output logic 	 i_oe,
     input wire [15:0] 	 i_din,
     output logic [15:0] d_addr,
     output logic 	 d_oe,
     input wire [15:0] 	 d_din,
     output logic [15:0] d_dout,
     output logic [1:0]  d_we
    
    
     );

   logic [15:0] 	 alu_ain, alu_bin, alu_dout;
   logic [3:0] 		 alu_op;
   logic [2:0] 		 reg_file_rnum1, reg_file_rnum2, reg_file_wnum;
   logic [15:0] 	 reg_file_dout1, reg_file_dout2, reg_file_din;
   logic 		 reg_file_we;
   
   logic [15:0] 	 ex_result_in;
   logic 		 ex_reg_file_we_in, ex_reg_file_we_reg;
   logic [15:0] 	 ex_result_reg; // Result Register
   logic [15:0] 	 ex_ir;         // Instruction Register


   
   
   alu16 alu16_inst(.ain(alu_ain), .bin(alu_bin), .op(alu_op), .dout(alu_dout));

   reg_file reg_file_inst
     (.clk(clk), .rst(rst), .we(reg_file_we),
      .rnum1(reg_file_rnum1), .rnum2(reg_file_rnum2), .wnum(reg_file_wnum),
      .dout1(reg_file_dout1), .dout2(reg_file_dout2), .din(reg_file_din));

   // IF (Instruction Fetch)   
   logic [15:0] 	 if_pc; // Program Counter
   logic [15:0] 	 if_ir; // Instruction Register

   logic [15:0] 	 if_pc_bta;
   logic 		 if_pc_we;
   
   always_ff @(posedge clk) begin
      if(rst)
	if_pc <= 16'd0;
      else if (if_pc_we == 1)
        if_pc <= if_pc_bta;
      else
        if_pc <= if_pc + 16'd2;
   end

   always_ff @(posedge clk) begin
      if (rst)
        if_ir <= 16'd0;
      else
        if_ir <= i_din;
   end

   assign i_oe = 1'b1;
   assign i_addr = if_pc;
   
   // ID (Instruction Decode)
   logic [15:0]   id_operand_reg1, id_operand_reg2; // Operand Registers
   logic [15:0]   id_ir; // Instruction Register
   logic [15:0]   id_imm_reg; // Immidiate Register
   logic [15:0]   id_pc;
   logic [15:0]  id_operand_in1, id_imm_in;


   assign reg_file_rnum1 = if_ir[10:8];
   assign reg_file_rnum2 = if_ir[7:5];
   assign if_pc_bta = (id_imm_in + if_pc);
   
   //
   always_ff @(posedge clk) begin
      if (rst)
        id_pc <= 16'd0;
      else 
        id_pc <= if_pc;
   end   

   //
   always_comb begin
      if (rst)
        id_operand_in1 <= 16'd0;
      else if(if_ir[10:8]== id_ir[10:8] && ex_reg_file_we_in == 1'b1)
	id_operand_in1 <= ex_result_in;
      else if(if_ir[10:8]==ex_ir[10:8] && ex_reg_file_we_reg == 1'b1)
	id_operand_in1 <= ex_result_reg;
      else 
        id_operand_in1 <= reg_file_dout1;
   end

   //
   always_ff @(posedge clk) begin
      if(rst)
	id_operand_reg1 <= 16'b0;
      else
	id_operand_reg1 <= id_operand_in1;
   end
   
   //
   always_comb begin
      if(if_ir[15:11] == 5'b10000 && id_operand_in1 == 16'b0)
	if_pc_we = 1'b1;
      else if(if_ir[15:11] == 5'b10001 && id_operand_in1 != 16'b0)
	if_pc_we = 1'b1;
      else if(if_ir[15:11] == 5'b10010 && id_operand_in1[15] == 1'b1)
	if_pc_we = 1'b1;
      else if(if_ir[15:11] == 5'b10011 && id_operand_in1[15] == 1'b0)
	if_pc_we = 1'b1;
      else if(if_ir[15:11] == 5'b11000)
	if_pc_we = 1'b1;
      else
	if_pc_we = 1'b0;
   end // always_comb

   //
   always_comb begin
      if(if_ir[15:11] == 5'b00100 || if_ir[15] == 1) begin
	 if(if_ir[7]==1)
	   id_imm_in[15:8] <= 8'b11111111;
	 else
	   id_imm_in[15:8] <= 8'b00000000;
      end
      else
	id_imm_in[15:8] <= 8'b00000000;
        id_imm_in[7:0] <= if_ir[7:0];
   end // always_comb
   
   //
   always_ff @(posedge clk) begin
      if (rst)
        id_imm_reg <= 16'd0;
      else
	id_imm_reg <= id_imm_in;
   end

   //
   always_ff @(posedge clk) begin
      if (rst) 
        id_ir <= 16'd0;
      else
        id_ir <= if_ir;
   end

   //
   always_ff @(posedge clk) begin
      if (rst)
        id_operand_reg2 <= 16'd0;
      else if(if_ir[7:5]== id_ir[10:8] & ex_reg_file_we_in == 1'b1)
	id_operand_reg2 <= ex_result_in;
      else if(if_ir[7:5]== ex_ir[10:8] & ex_reg_file_we_reg == 1'b1)
	id_operand_reg2 <= ex_result_reg;
      else 
        id_operand_reg2 <= reg_file_dout2;
   end
   /*
    always_ff @(posedge clk) begin
    if (rst)
    id_operand_reg1 <= 16'd0;
    else if(if_ir[10:8]== id_ir[10:8] & ex_reg_file_we_in == 1)
    id_operand_reg1 <= ex_result_in;
    else if(if_ir[10:8]==ex_ir[10:8] & reg_file_we == 1)
    id_operand_reg1 <= ex_result_reg;
    else 
    id_operand_reg1 <= reg_file_dout1;
   end
    */

   /*
    //(1)
    always_ff@(posedge clk) begin
    if(rst)
    id_imm_reg <= 16'd0;
    else
    case(if_ir[15:11])
    5'b00100: id_imm_reg = (if_ir[7]==1)?{8'hff,if_ir[7:0]}:{8'h00,if_ir[7:0]};
    5'b01010: id_imm_reg = {8'h00, if_ir[7:0]};
    5'b01011: id_imm_reg = {8'h00, if_ir[7:0]};
    5'b00001: id_imm_reg = {8'h00, if_ir[7:0]};
    5'b00110: id_imm_reg = {8'h00, if_ir[7:0]};
    5'b10000: id_imm_reg = (if_ir[7]==1)?{8'hff,if_ir[7:0]}:{8'h00,if_ir[7:0]};
    5'b10001: id_imm_reg = (if_ir[7]==1)?{8'hff,if_ir[7:0]}:{8'h00,if_ir[7:0]};
    5'b10010: id_imm_reg = (if_ir[7]==1)?{8'hff,if_ir[7:0]}:{8'h00,if_ir[7:0]};
    5'b10011: id_imm_reg = (if_ir[7]==1)?{8'hff,if_ir[7:0]}:{8'h00,if_ir[7:0]};
    5'b11000: id_imm_reg = (if_ir[7]==1)?{8'hff,if_ir[7:0]}:{8'h00,if_ir[7:0]};
    default : id_imm_reg = 16'd0;
	endcase // case (if_ir[15;11])
   end // always_ff@
    */

   
   // EX (Exectution)

   logic [15:0]       ex_operand_reg1;

   //
   always_ff @(posedge clk) begin
      if(rst)
	ex_operand_reg1 <= 16'd0;
      else
	ex_operand_reg1 = id_operand_reg1;
   end

   // assign alu_ain = id_operand_reg1;
   // assign alu_bin = id_operand_reg2;
   // assign alu_op = id_ir[3:0];

   //onew


   //
   assign ex_reg_file_we_in = (id_ir == 16'h0000 ||  id_ir[15] == 1'h1 || (id_ir[15:11]==5'd0 && id_ir[4:0]==5'b10000) || (id_ir[15:11]==5'd0 && id_ir[4:0]==5'b10010))? 1'b0 : 1'b1;

//
   always_ff @(posedge clk) begin
      if (rst)
        ex_reg_file_we_reg <= 16'd0;
      else
        ex_reg_file_we_reg <= ex_reg_file_we_in;
   end
   

   //   
   assign d_addr = id_operand_reg2;

   //
   always_comb begin
      if(id_ir[15:11]==5'd0 && id_ir[4]==1'd1 && (id_ir[3:0]==4'b0011 || id_ir[3:0]==4'b0001))//lw, lbu
	d_oe = 1'd1;
      else
	d_oe = 1'd0;
   end
   

   //mendo
   always_comb begin
      if(id_ir[15:11]==5'd0 && id_ir[4]==1'd1 && id_ir[0]==1'd0) //store
	if(id_ir[3:0]==4'b0010 && id_operand_reg2[0]==1'd0) begin //sbu even
	   d_dout[15:8] = id_operand_reg1[7:0];
	   d_dout[7:0] = 8'd0;
	end
	else 
	  d_dout = id_operand_reg1;
      
      else 
	d_dout = 16'd0;
      
   end // always_comb

   //
   always_comb begin
	   if(id_ir[15:11]==5'b0 && id_ir[4:0] == 5'b10000)
		   d_we = 2'b11;
	   else if(id_ir[15:11]==5'b0 && id_ir[4:0] == 5'b10010)begin
		   if(id_operand_reg2[0] == 1'b0)
			   d_we = 2'b01;
		   else
			   d_we = 2'b10;
	   end
	   else
		   d_we = 2'b00;
   end
		   
//
   always_ff @(posedge clk) begin
      if(rst)
	ex_result_reg <= 16'd0;
      else
	ex_result_reg <= ex_result_in;
   end

//
   always_comb begin
	   if(rst)
		   ex_result_in =16'b0;
	   else if(id_ir[15:11] == 5'b0)begin
		   if(id_ir[4:0] == 5'b1011 && id_operand_reg2[0] == 1'b1)begin
			   ex_result_in[7:0] = d_din[7:0];
			   ex_result_in[15:8] = 8'b0;
		   end
		   else if(id_ir[4:0] == 5'b1011 && id_operand_reg2[0] == 1'b0)begin
			   ex_result_in[7:0] = d_din[15:8];
			   ex_result_in[15:8] = 8'b0;
		   end
		   else if(id_ir[4:0] == 5'b10001)
			   ex_result_in = d_din;
		   else
			   ex_result_in = alu_dout;
	   end
	   else
		   ex_result_in = alu_dout;
   end
   
   

   //
   always_comb begin
      if(id_ir[15] == 1'b1)
	alu_ain = id_pc;
      else
	alu_ain = id_operand_reg1;
   end
//
   always_ff @(posedge clk) begin
      if (rst)
        ex_ir <= 16'd0;
      else
        ex_ir <= id_ir;
   end

   //
   always_comb begin
      if(id_ir[15] == 1'b1)
	alu_op <= 4'b0100;
      else
	if (id_ir[14:11] == 4'b0000 )
          alu_op <= id_ir[3:0];
        else
          alu_op <= id_ir[14:11];
   end
   
   
   //
   always_comb begin
      if (id_ir[15:11] == 5'b00000)
        alu_bin = id_operand_reg2;
      else
        alu_bin = id_imm_reg;
   end
   
   // WB (Write Back)
   assign reg_file_wnum = ex_ir[10:8];
   assign reg_file_din = ex_result_reg;
   //assign reg_file_we = (ex_ir == 16'h0000 || ex_ir[15] == 1'h1)? 1'b0: 1'b1;
   //assign reg_file_we = (ex_ir == 16'h0000 ||  ex_ir[15] == 1'h1 || (ex_ir[15:11]==5'd0 && ex_ir[4:0]==5'b10000) || (ex_ir[15:11]==5'd0 && ex_ir[4:0]==5'b10010))? 1'b0 : 1'b1;


   assign reg_file_we = ex_reg_file_we_reg;
   

   // for debug
   // assign debug_out = (reg_file_we)? reg_file_din: 16'h0000;
   // assign if_pc_bta = ex_result_reg;
   
endmodule


module reg_file
  (
   input wire 	       clk, rst,
   input wire [2:0]    rnum1, rnum2,
   output logic [15:0] dout1, dout2,
   input wire [2:0]    wnum,
   input wire [15:0]   din,
   input wire 	       we
   );

   logic [15:0]        registers[8];

   assign dout1 = registers[rnum1];
   assign dout2 = registers[rnum2];

   always_ff @(posedge clk) begin
      if (rst)
	registers <= '{default: 16'h0000};
      else if (we)
	registers[wnum] <= din;
   end
endmodule


module alu16
  (
   input wire [15:0]   ain, bin,
   input wire [3:0]    op,
   output logic [15:0] dout
   );

   always_comb begin
      case(op)
	4'b0000 : dout = ain;
	4'b0001 : dout = bin;
	4'b0010 : dout = ~bin;
//	4'b0011 : dout = ain ^ bin;
	4'b0100 : dout = ain + bin;
	4'b0101 : dout = ain - bin;
	4'b0110 : dout = bin << 8;
	4'b0111 : dout = bin >> 8;
	4'b1000 : dout = bin << 1;
	4'b1001 : dout = bin >> 1;
	4'b1010 : dout = ain & bin;
	4'b1011 : dout = ain|bin;
	4'b1100 : begin
		if(ain - bin < 0)
	     dout = 255 + ain - bin;
	   else
	     dout = 255 - ain + bin;
	end
	default : dout = 16'bx;
      endcase // case (op)
   end

endmodule

`default_nettype wire
