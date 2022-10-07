/*
	Assignment 3: Single Cycle CPU
	EE2003: Computer Organization
	Author: Ayush Jamdar
	Date started: September 22, 22
	Last Modified: 
	
	Abstract: To implement all the instructions of the 
		RISC-V 32I instruction set.
		
	References 
	1. https://en.wikichip.org/wiki/risc-v/registers
	2. https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html
	
	To Check:
	1. signed/unsigned comparisons in registers
	2. to check load seq implementation
*/

module cpu (
    input clk, 
    input reset,
    output [31:0] iaddr,
    input [31:0] idata,
    output [31:0] daddr,
    input [31:0] drdata,
    output [31:0] dwdata,
    output [3:0] dwe
);
    reg [31:0] iaddr;
    reg [31:0] daddr;
    reg [31:0] dwdata;
    reg [3:0]  dwe;
    
    // Create a register file
    // 32 registers, each 32-bit wide
    // to infer a D-FF, used the _d and _q regs
    // registers[which register][which bit of register]
   	reg [31:0] registers_d [31:0];
   	reg [31:0] registers_q [31:0];
	integer i, k;
	
	wire [4:0] rs1, rs2;
	wire [11:0] imm;
	
	assign rs1 = idata[19:15];
	assign rs2 = idata[24:20];
	assign imm = idata[31:20];
	
    always @(posedge clk) begin
        if (reset) begin
            iaddr 	<= 0;
            daddr 	<= 0;
            dwdata 	<= 0;
            dwe		<= 0;
            // clear all registers
            for (i = 0; i < 32; i = i + 1) begin
            	// registers_d[i][31:0]	<= 32'b0;
            	registers_q[i][31:0]	<= 32'b0;
            end
            
        end 
        else begin			        	
			for (i = 0; i < 32; i = i + 1) begin
				registers_q[i]	<= registers_d[i];
			end
			iaddr 	<= iaddr + 4;
        end
    end
    
    
    always@(*) begin
    	// All instructions except dmem Load are combinational in a single cycle CPU.
    	// default for all registers
    	for (i = 0; i < 32; i = i + 1) begin
           	registers_d[i]	= registers_q[i];
        end
    	
    	// Start with decoding the instruction
    	case (idata[6:0])
    		7'b0110111: begin 
    			// U-Type
	    		// LUI
	    		registers_d[idata[11:7]] = ({idata[31:12], 12'b0});
	    	end
	    	
	    	7'b0010111: begin
	    		// AUIPC - add upper immediate to pc
	    		registers_d[idata[11:7]] = iaddr + (idata[31:12] << 12);
	    		// CHECK
	    	end
	    	
	    	7'b0010011: begin
		    		// Immediate instructions
		    		case (idata[14:12])
		    			3'b000: begin
		    				// ADDI - add immediate
		    				registers_d[idata[11:7]] = registers_q[rs1] + {{20{idata[31]}}, imm};
		    			end
		    				
		    			3'b010: begin 
		    				// SLTI - set less than immediate
		    				registers_d[idata[11:7]] = ($signed(registers_q[rs1]) < $signed({{20{idata[31]}}, imm})) ? 1 : 0;
		    			end
		    				
		    			3'b011: begin 
		    				// SLTIU - set less than immediate (unsigned) 
		    				registers_d[idata[11:7]] = (registers_q[rs1] < {{20{1'b0}}, imm}) ? 1 : 0;
		    			end
		    				
		    			3'b100: begin
		    				// XORI - xor immediate      
		    				registers_d[idata[11:7]] = (registers_q[rs1]) ^ {{20{1'b0}}, imm};
		    			end
		    				
		    			3'b110: begin 
		    				// ORI - or immediate
		    				registers_d[idata[11:7]] = registers_q[rs1] | {{20{idata[31]}}, imm};
		    			end				
		    				
		    			3'b111: begin
		    				// ANDI - and immediate
		    				registers_d[idata[11:7]] = registers_q[rs1] & {{20{idata[31]}}, imm};
		    			end
		    				
		    			3'b001: begin
		    				// SLLI - shift logical left
		    				registers_d[idata[11:7]] = registers_q[rs1] << rs2;
		    			end
		    				
		    			3'b101: begin
		    				if (idata[31:27] == 00000) 
			    				// SRLI - shift logical right
			    				registers_d[idata[11:7]] = registers_q[rs1] >> rs2;
			    			else if (idata[31:27] == 01000)
			    				// SRAI - shift right arithmetic
		    					registers_d[idata[11:7]] = registers_q[rs1] >>> rs2;
		    			end
		    		endcase
		    end
		    
		    7'b0110011: begin
                case(idata[31:25])
                    7'b000_0000: begin
                        case(idata[14:12])
                            3'b000: begin // ADD
                                registers_d[idata[11:7]] = registers_q[rs1] + registers_q[rs2];
                            end
                            3'b001: begin  // SLL
                                registers_d[idata[11:7]] = registers_q[rs1] << registers_q[rs2][4:0];
                            end
                            3'b010: begin  // SLT
                                registers_d[idata[11:7]] = ($signed(registers_q[rs1]) < ($signed(registers_q[rs2]))) ? 1 : 0;
                            end
                            3'b011: begin  // SLTU
                                registers_d[idata[11:7]] = (registers_q[rs1] < registers_q[rs2]) ? 1 : 0;
                            end
                            3'b100: begin  // XOR
                                registers_d[idata[11:7]] = registers_q[rs1] ^ registers_q[rs2];			end
                            3'b101: begin  // SRL
                                registers_d[idata[11:7]] = registers_q[rs1] >> registers_q[rs2][4:0];
                            end
                            3'b110: begin  // OR
                                registers_d[idata[11:7]] = registers_q[rs1] | registers_q[rs2];
                            end
                            3'b111: begin  // AND
                                registers_d[idata[11:7]] = registers_q[rs1] & registers_q[rs2];
                            end
                        endcase
                    end
                    7'b010_0000: begin
                        case(idata[14:12])
                            3'b000: begin // SUB
                                registers_d[idata[11:7]] = registers_q[rs1] - registers_q[rs2]; 
                            end
                            3'b101: begin // SRA
                                registers_d[idata[11:7]] = registers_q[rs1] >>> registers_q[rs2][4:0];
                            end
                        endcase
                    end
                endcase
			end
			
			7'b0000011: begin
		    		case(idata[14:12])
		    			3'b000: begin
		    				// LB - load byte
		    				daddr = registers_q[rs1] + {{20{idata[31]}}, imm};
		    				registers_d[idata[11:7]] = {{24{drdata[7]}}, drdata[7:0]};
		    				// as soon as data address is given, it is assumed that the data will be obtained
		    			end
		    			
		    			3'b001: begin
		    				// LH - load half word
		    				daddr = registers_q[rs1] + {{20{idata[31]}}, imm};
		    				registers_d[idata[11:7]] = {{16{drdata[7]}}, drdata[15:0]};
		    			end
		    			
		    			3'b010: begin
		    				// LW - load word
		    				daddr = registers_q[rs1] + {{20{idata[31]}}, imm};
		    				registers_d[idata[11:7]] = drdata;
		    			end		
		    			
		    			3'b100: begin
		    				// LBU - load byte unsigned
		    				daddr = registers_q[rs1] + {{20{idata[31]}}, imm};
		    				registers_d[idata[11:7]] = {{24{1'b0}}, drdata[7:0]};
		    				// CHECK
		    			end
		    			
		    			3'b101: begin
		    				// LHU - load halfword unsigned
		    				daddr = registers_q[rs1] + {{20{idata[31]}}, imm};
		    				registers_d[idata[11:7]] = {{24{1'b0}}, drdata[15:0]};
		    			end
		    		endcase
		    end
		    
		    7'b0100011: begin
		    		case(idata[14:12])
		    			3'b000: begin
		    				// SB - store byte in lower 8 bits of memory
		    				daddr 	= registers_q[rs1] + {{20{idata[31]}}, {idata[31:25], idata[11:7]}};
		    				dwe 	= 1'b1 << daddr[1:0];
		    				dwdata 	= {{24{1'b0}}, registers_q[rs2][7:0]};
		    			end
		    			// imm = imm rd = idata[11:7]
		    			3'b001: begin
		    				// SH - store halfword in lower 16 bits of memory
		    				daddr 	= registers_q[rs1] + {{20{idata[31]}}, {idata[31:25], idata[11:7]}};
		    				dwe 	= daddr[1] ? 4'b1100 : 4'b0011;
		    				dwdata 	= {{16{1'b0}}, registers_q[rs2][15:0]};
		    			end
		    			
		    			3'b010: begin
		    				// SW - store word
		    				dwe 	= 4'b1111;
		    				daddr 	= registers_q[rs1] + {{20{idata[31]}}, {idata[31:25], idata[11:7]}};
		    				dwdata 	= registers_q[rs2];
		    			end		    			
		    		endcase
		    end
		endcase		
    end
endmodule   
    
    

