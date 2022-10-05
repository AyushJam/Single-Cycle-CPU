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
	reg [31:0] pc_d;
	reg [31:0] pc_q;
	
	 
    always @(posedge clk) begin
        if (reset) begin
            iaddr 	<= 0;
            daddr 	<= 0;
            dwdata 	<= 0;
            dwe		<= 0;
            registers_d <= `{default: 0};
            registers_q <= `{default: 0};
            // pc 		<= 0;
            // check the previous line
        end 
        else begin
        	registers_q		<= registers_d;
        	iaddr 			<= iaddr + 4;
        	// dmem logic? write is handled in the dmem block
        end
    end
    
    
    always@(*) begin
    	// All instructions except dmem Load are combinational in a single cycle CPU.
    	// default for all registers
    	registers_d = registers_q;
    	
    	// Start with decoding the instruction
    	case (idata[6:0])
    		7'b0110111: begin
	    		// LUI
	    		registers_d[idata[11:7]] = (idata[31:12] << 12);
	    	end
	    	
	    	7'b0010111: begin
	    		// AUIPC - add upper immediate to pc
	    		registers_d[idata[11:7]] = iaddr + (idata[31:12] << 12);
	    	end
	    	
	    	7'b0010011: begin
		    		// Immediate instructions
		    		case (idata[14:12])
		    			3'b000: begin
		    				// ADDI - add immediate
		    				registers_d[idata[11:7]] = registers_q[idata[19:15]] + {{20{idata[31]}}, idata[31:20]};
		    			end
		    				
		    			3'b010: begin 
		    				// SLTI - set less than immediate
		    				registers_d[idata[11:7]] = (registers_q[idata[19:15]] < {{20{idata[31]}}, idata[31:20]}) ? 1 : 0;
		    			end
		    				
		    			3'b011: begin 
		    				// SLTIU - set less than immediate (unsigned) 
		    				registers_d[idata[11:7]] = (registers_q[idata[19:15]] < {{20{0}}, idata[31:20]}) ? 1 : 0;
		    			end
		    				
		    			3'b100: begin
		    				// XORI - xor immediate      
		    				registers_d[idata[11:7]] = (registers_q[idata[19:15]]) ^ {{20{0}}, idata[31:20]};
		    			end
		    				
		    			3'b110: begin 
		    				// ORI - or immediate
		    				registers_d[11:7] = registers_q[idata[19:15]] | {{20{idata[31]}}, idata[31:20]};
		    			end				
		    				
		    			3'b111: begin
		    				// ANDI - and immediate
		    				registers_d[11:7] = registers_q[idata[19:15]] & {{20{idata[31]}}, idata[31:20]};
		    			end
		    				
		    			3'b001: begin
		    				// SLLI - shift logical left
		    				registers_d[11:7] = registers_q[idata[19:15]] << idata[24:20];
		    			end
		    				
		    			3'b101: begin
		    				if (idata[31:27] == 00000) 
			    				// SRLI - shift logical right
			    				registers_d[11:7] = registers_q[idata[19:15]] >> idata[24:20];
			    			else if (idata[31:27] == 01000)
			    				// SRAI - shift right arithmetic
		    					registers_d[11:7] = registers_q[idata[19:15]] >>> idata[24:20];
		    			end
		    		endcase
		    end
		    
		    7'b0110011: begin
		  			case (idata[14:12]) 
		  				3'b000: begin
		  					if (idata[31:27] == 00000)
		  						// ADD
		  						registers_d[idata[11:7]] = registers_q[idata[19:15]] + registers_q[idata[24:20]];
		  					else if (idata[31:27] == 01000)
		  						// SUB
		  						registers_d[idata[11:7]] = registers_q[idata[19:15]] - registers_q[idata[24:20]]; 
		  				end
		  				
		  				3'b001: begin
		  					// SLL - shift left logical
		  					registers_d[idata[11:7]] = registers_q[idata[19:15]] << registers_q[idata[24:20]];
		  				end
		  				
		  				3'b010: begin
		  					// SLT - signed compare / set on less than
		  					registers_d[idata[11:7]] = registers_q[idata[19:15]] < registers_q[idata[24:20]] ? 1'd1 : 1'd0;
		  				end
		  				
		  				3'b011: begin
		  					// SLTU - unsigned compare / set on less than unsigned
		  					// CHECK THIS!!
		  					registers_d[idata[11:7]] = registers_q[idata[19:15]] < registers_q[idata[24:20]] ? 1'd1 : 1'd0;
		  				end
		  				
		  				3'b100: begin
		  					// XOR
		  					registers_d[idata[11:7]] = registers_q[idata[19:15]] ^ registers_q[idata[24:20]];
		  				end
		  				
		  				3'b101: begin
			  				if(idata[31:27] == 00000)
			  					// SRL
			  					registers_d[idata[11:7]] = registers_q[idata[19:15]] >> registers_q[idata[24:20]];
			  				else if (idata[31:27] == 01000)
			  					registers_d[idata[11:7]] = registers_q[idata[19:15]] >>> registers_q[idata[24:20]];
		  				end
		  				
		  				3'b111: begin
		  					// AND
		  					registers_q[idata[11:7]] = registers_q[idata[19:15]] & registers_q[idata[24:20]];
		  				end
		  			endcase
			end
			
			7'b0000011: begin
		    		case(idata[14:12])
		    			3'b000: begin
		    				// LB - load byte
		    				daddr = registers_q[idata[19:15]] + {{20{idata[31]}}, idata[31:20]};
		    				registers_d[idata[11:7]] = {{24{drdata[7]}}, drdata[7:0]};
		    				// as soon as data address is given, it is assumed that the data will be obtained
		    			end
		    			
		    			3'b001: begin
		    				// LH - load half word
		    				daddr = registers_q[idata[19:15]] + {{20{idata[31]}}, idata[31:20]};
		    				registers_q[idata[11:7]] = {{16{drdata[7]}}, drdata[15:0]};
		    			end
		    			
		    			3'b010: begin
		    				// LW - load word
		    				daddr = registers_q[idata[19:15]] + {{20{idata[31]}}, idata[31:20]};
		    				registers_d[idata[11:7]] = drdata;
		    			end		
		    			
		    			3'b100: begin
		    				// LBU - load byte unsigned
		    				daddr = registers_q[idata[19:15]] + {{20{idata[31]}}, idata[31:20]};
		    				registers_d[idata[11:7]] = {{24{0}}, drdata[7:0]};
		    			end
		    			
		    			3'b101: begin
		    				// LHU - load halfword unsigned
		    				daddr = registers_q[idata[19:15]] + {{20{idata[31]}}, idata[31:20]};
		    				registers_d[idata[11:7]] = {{24{0}}, drdata[15:0]};
		    			end
		    		endcase
		    end
		    
		    7'b0100011: begin
		    		case(idata[14:12])
		    			3'b000: begin
		    				// SB - store byte in lower 8 bits of memory
		    				dwe 	= 4'b0001;
		    				daddr 	= registers_q[idata[19:15]] + {{27{idata[11]}}, idata[11:7]};
		    				dwdata 	= {{24{1'b0}}, registers_q[idata[24:20]][7:0]};
		    			end
		    			
		    			3'b000: begin
		    				// SH - store halfword in lower 16 bits of memory
		    				dwe 	= 4'b0011;
		    				daddr 	= registers_q[idata[19:15]] + {{27{idata[11]}}, idata[11:7]};
		    				dwdata 	= {{16{1'b0}}, registers_q[idata[24:20]][15:0]};
		    			end
		    			
		    			3'b000: begin
		    				// SW - store word
		    				dwe 	= 4'b1111;
		    				daddr 	= registers_q[idata[19:15]] + {{27{idata[11]}}, idata[11:7]};
		    				dwdata 	= registers_q[idata[24:20]];
		    			end		    			
		    		endcase
		    end
		endcase		
    end
endmodule   
    
    
