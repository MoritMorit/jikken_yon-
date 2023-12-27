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
   


   
   always_ff@(posedge clk) begin
      if (rst)
        if_pc <= 16'd0;
      else  begin 
         if(if_pc_we == 1'b1)
	   if_pc <= if_pc_bta;
         else
           if_pc <= if_pc + 16'd2;
      end
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
   logic [15:0]   id_operand_reg1, id_operand_reg2,id_imm_reg; // Operand Registers
   logic [15:0]   id_ir; // Instruction Register
   logic [15:0]   id_pc;
   logic [15:0]   ex_result_reg;
   logic [15:0]   ex_ir;
   logic [15:0]   ex_result_in;
   logic 	  reg_file_we_in;
   logic [15:0]   id_operand_in1;
   logic [15:0]   id_imm_in;
   
   
   assign reg_file_rnum1 = if_ir[10:8];
   assign reg_file_rnum2 = if_ir[7:5];
   


   always_comb begin
      if(if_ir[15] == 1'b1)
	id_imm_in <= (if_ir[7] == 1'b1)? { 8'b11111111, if_ir[7:0]}:{ 8'b00000000, if_ir[7:0]};
      else
	case(if_ir[15:11])
	  5'b00100: id_imm_in <= (if_ir[7] == 1'b1)? { 8'b11111111, if_ir[7:0]}:{ 8'b00000000, if_ir[7:0]};
	  5'b01010: id_imm_in <= { 8'b00000000, if_ir[7:0]} ;
	  5'b01011: id_imm_in <= { 8'b00000000, if_ir[7:0]};
	  5'b00001: id_imm_in <= { 8'b00000000, if_ir[7:0]};
	  5'b00110: id_imm_in <= { 8'b00000000, if_ir[7:0]};
	  default:  id_imm_in <= 16'h0000;
	endcase // case (if_ir[15:11])
      
      
   end // always_comb
   


   always_ff @(posedge clk) begin
      if (rst)
        id_imm_reg <= 16'd0;
      else
	id_imm_reg <= id_imm_in;
      
   end // always_ff @

   always_ff @(posedge clk) begin
      if (rst)
        id_pc <= 16'd0;
      else 
        id_pc <= if_pc;
   end
   
   always_comb begin
      if(reg_file_we_in == 1'b1 && id_ir[10:8] == if_ir[10:8])
	id_operand_in1 <= ex_result_in;
      else if(reg_file_we == 1'b1 && ex_ir[10:8] == if_ir[10:8])
	id_operand_in1 <= ex_result_reg;
      else
	id_operand_in1 <= reg_file_dout1;
   end

   always_comb begin
      if(if_ir[15:11] == 5'b10000)
	if(id_operand_in1 == 16'd0)
	  if_pc_we = 1'b1;
	else
	  if_pc_we = 1'b0;
      
      else if(if_ir[15:11] == 5'b10001)
	if(id_operand_in1 != 16'd0)
          if_pc_we = 1'b1;
	else
	  if_pc_we = 1'b0;

      else if(if_ir[15:11] == 5'b10010)
	if(id_operand_in1[15] == 1'b1)
          if_pc_we = 1'b1;
	else
	  if_pc_we = 1'b0;

      else if(if_ir[15:11] == 5'b10011)
	if(id_operand_in1[15] == 1'b0)
          if_pc_we = 1'b1;
	else
	  if_pc_we = 1'b0;
      else if(if_ir[15:11] == 5'b11000)
	if_pc_we = 1'b1;
      
      else
	if_pc_we = 1'b0;
   end // always_comb


   assign if_pc_bta = id_imm_in + if_pc;
   
   
   always_ff @(posedge clk) begin
      if (rst)
        id_operand_reg1 <= 16'd0;
      else
	id_operand_reg1 <= id_operand_in1;
      
   end
   
   always_ff @(posedge clk) begin
      if (rst)
        id_operand_reg2 <= 16'd0;
      else if(reg_file_we_in == 1'b1 && id_ir[10:8] == if_ir[7:5])
	id_operand_reg2 <= ex_result_in;
      else if(reg_file_we == 1'b1 && ex_ir[10:8] == if_ir[7:5])
	id_operand_reg2 <= ex_result_reg;
      else
        id_operand_reg2 <= reg_file_dout2;
   end

   always_ff @(posedge clk) begin
      if (rst) 
        id_ir <= 16'd0;
      else
        id_ir <= if_ir;
   end
   
   // EX (Exectution)
   // logic [15:0] ex_result_reg; // Result Register
   // Instruction Register
   logic [15:0] ex_operand_reg;
   
   logic [15:0] ex_operand_reg1;

   assign d_addr = id_operand_reg2;

   always_comb begin
      if(id_ir[15:11] == 5'b00000 && id_ir[4:0] == 5'b10001)
	d_oe = 1'b1;
      else if(id_ir[15:11] == 5'b00000 && id_ir[4:0] == 5'b10011)
	d_oe = 1'b1;
      else
	d_oe = 1'b0;
   end

   always_comb begin
      if(id_ir[15:11]== 5'b00000 && id_ir[4:0] == 5'b10010)begin
	 if(id_operand_reg2[0] == 1'b0)begin
	    d_dout[15:8] <= id_operand_reg1[7:0];
            d_dout[7:0] = 8'b00000000;
	 end
	 
	 else
	   d_dout <= id_operand_reg1;
      end
      
      else
	d_dout <= id_operand_reg1;
   end

   always_comb begin
      if(id_ir[15:11]== 5'b00000 && id_ir[4:0] == 5'b10000)begin
	 d_we[1] = 1'b1;
      	 d_we[0] = 1'b1;
      end
      else if(id_ir[15:11]== 5'b00000 && id_ir[4:0] == 5'b10010)begin
       	 if(id_operand_reg2[0] == 1'b0)begin
	    d_we[0] = 1'b1;
	    d_we[1] = 1'b0;
	 end
	 
	 else begin
	    d_we[0] = 1'b0;	 
	    d_we[1] = 1'b1;
	 end
	 
      end
      else begin
	 d_we[1] = 1'b0;
      	 d_we[0] = 1'b0;
      end // else: !if(id_operand_reg2[0] == 1'b0)
      
   end // always_comb





   

   
   always_comb begin
      if (id_ir[15] == 1'b1)
	alu_op = 4'b0100; // ALUに加算を指示
      else if (id_ir[15:11] == 5'b00000)
	alu_op = id_ir[3:0];
      else
	alu_op = id_ir[14:11];
   end
   
   always_comb begin
      if(id_ir[15:11] == 5'b00000)
	alu_bin <= id_operand_reg2;
      
      else
        alu_bin <= id_imm_reg;
      
   end
   // always_comb begin
   //  if(id_ir[15] == 1'b1)
   //	alu_bin <= id_imm_reg;   
   //    else
   //   alu_bin <= id_operand_reg2;
   
   //  end

   always_comb begin
      if(id_ir[15] == 1'b1)
        alu_ain <= id_pc;	    
      else
        alu_ain <= id_operand_reg1; 
      
   end	    
   
   

   always_ff @(posedge clk) begin
      if (rst) 
        ex_operand_reg1 <= 16'd0;
      else
        ex_operand_reg1 <= id_operand_reg1;
   end


   //ex_operand_reg

   always_comb begin
      if(id_ir[15:11]== 5'b00000 && id_ir[4:0] == 5'b10011)begin
	 if(id_operand_reg2[0] == 1'b0)begin
	    ex_result_in[7:0] <= d_din[15:8];
	    ex_result_in[15:8] = 8'b00000000;
	 end
	 else begin
	    ex_result_in[15:8] = 8'b00000000;
	    ex_result_in[7:0] <= d_din[7:0];
	 end
      end
      
      else if(id_ir[15:11]== 5'b00000 && id_ir[4:0] == 5'b10001)
	ex_result_in <= d_din;
      
      else
        ex_result_in <= alu_dout;
   end // always_comb
   
   

   
   always_ff @(posedge clk) begin
      if (rst) 
        ex_result_reg <= 16'd0;
      else
	ex_result_reg <= ex_result_in;
   end
   
   
   always_ff @(posedge clk) begin
      if (rst)
        ex_ir <= 16'd0;
      else
        ex_ir <= id_ir;
   end
   
   // WB (Write Back)
   assign reg_file_wnum = ex_ir[10:8];
   assign reg_file_din = ex_result_reg;
   logic ex_reg_file_we_reg;

   


   always_comb begin
      if(id_ir == 16'd0)
	reg_file_we_in = 1'b0;

      
      else if(id_ir[15] == 1'b1)
	reg_file_we_in = 1'b0;
      
      else if(id_ir[15:11] == 8'b00000 && id_ir[4:0] == 5'b10000)
	reg_file_we_in = 1'b0;

      else if(id_ir[15:11] == 8'b00000 && id_ir[4:0] == 5'b10010)
	reg_file_we_in = 1'b0;
      
      else
	reg_file_we_in = 1'b1;
   end // always_comb
   
   always_ff@(posedge clk)begin
      if(rst)
	ex_reg_file_we_reg <= 16'd0;
      else
	ex_reg_file_we_reg <= reg_file_we_in;
   end

   assign reg_file_we = ex_reg_file_we_reg;
   
   
endmodule



module reg_file
  (
   input wire 	       clk,rst,
   input wire [2:0]    rnum1,rnum2,
   output logic [15:0] dout1,dout2,
   input wire [2:0]    wnum,
   input wire [15:0]   din,
   input wire 	       we
   );

   logic [15:0]        registers[8];

   assign dout1 = registers[rnum1];
   assign dout2 = registers[rnum2];

   always_ff @(posedge clk) begin
      if(rst)
	registers <= '{default: 16'h0000};
      else if(we)
	registers[wnum] <= din;
   end
endmodule // reg_file

module alu16
  (
   input wire [15:0]   ain, bin,
   input wire [3:0]    op,
   output logic [15:0] dout
   );

   always_comb begin
      case(op)
	4'b0000 : dout <= ain;
	4'b0001 : dout <= bin;
	4'b0010 : dout <= ~bin;
	//4'b0011 : dout <= ain^bin;
	4'b0100 : dout <= ain + bin;
	4'b0101 : dout <= ain - bin;
	4'b0110 : dout <= bin << 8;
	4'b0111 : dout <= bin >> 8;
	4'b1000 : dout <= bin << 1;
	4'b1001 : dout <= bin >> 1;
	4'b1010 : dout <= ain&bin;
	4'b1011 : dout <= ain|bin;
	
	default : dout <= 16'bx;
	
      endcase

   end

endmodule

`default_nettype wire
