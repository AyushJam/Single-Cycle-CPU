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
   	reg [31:0] registers [31:0];
	reg [31:0] pc;
	 
    always @(posedge clk) begin
        if (reset) begin
            iaddr <= 0;
            daddr <= 0;
            dwdata <= 0;
            dwe <= 0;
            registers <= 0;
            pc <= 0;
            // check the previous line
            
        end else begin 
        // Start Computation
        
        	case idata[6:0]:
        	7'b0110111: begin
        		// LUI
        		registers[idata[11:7]] <= idata[31:12] << 12;
        	end
        	
        	7'b0010111: begin
        		// AUIPC - add upper immediate to pc
        		registers[idata[11:7]] <= pc + (idata[31:12] << 12);
        	end
        		
        	7'b0010011: begin
        		// Immediate instructions
        		case idata[14:12]:
        			3'b000: begin
        				// ADDI - add immediate
        				registers[idata[11:7]] <= registers[idata[19:15]] + {20{idata[31]}, idata[31:20]};
        			end
        				
        			3'b010: begin 
        				// SLTI - set less than immediate
        				registers[idata[11:7]] <= (registers[idata[19:15]] < {20{idata[31]}, idata[31:20]} ? 1 : 0;
        			end
        				
        			3'b011: begin 
        				// SLTIU - set less than immediate (unsigned) 
        				registers[idata[11:7]] <= (registers[idata[19:15]] < {20{0}, idata[31:20]} ? 1 : 0;
        			end
        				
        			3'b100: begin
        				// XORI - xor immediate      
        				registers[11:7] <= registers[idata[19:15]] ^ {20{idata[31]}, idata[31:20]};
        			end
        				
        			3'b110: begin 
        				// ORI - or immediate
        				registers[11:7] <= registers[idata[19:15]] | {20{idata[31]}, idata[31:20]};
        			end				
        				
        			3'b111: begin
        				// ANDI - and immediate
        				registers[11:7] <= registers[idata[19:15]] & {20{idata[31]}, idata[31:20]};
        			end
        				
        			3'b001: begin
        				// SLLI - shift logical left
        				registers[11:7] <= registers[idata[19:15]] << idata[24:20];
        			end
        				
        			3'b101: begin
        				if (idata[31:27] == 00000) 
	        				// SRLI - shift logical right
    	    				registers[11:7] <= registers[idata[19:15]] >> idata[24:20];
    	    			else if (idata[31:27] == 01000)
    	    				// SRAI - shift right arithmetic
        					registers[11:7] <= registers[idata[19:15]] >>> idata[24:20];
        			end
        		endcase
        	end
        	     		
      		7'b0110011: begin
      			case idata[14:12]: 
      				3'b000: begin
      					if (idata[31:27] == 00000)
      						// ADD
      						registers[idata[11:7]] <= registers[idata[19:15]] + registers[idata[24:20]];
      					else if (idata[31:27] == 01000)
      						// SUB
      						registers[idata[11:7]] <= registers[idata[19:15]] - registers[idata[24:20]]; 
      				end
      				
      				3'b001: begin
      					// SLL
      					registers[idata[11:7]] <= registers[idata[19:15]] << registers[idata[24:20]];
      				end
      				
      				3'b010: begin
      					// SLT
      					registers[idata[11:7]] <= registers[idata[19:15]] < registers[idata[24:20]] ? 1 : 0;
      				end
      				
      				3'b011: begin
      					// SLTU
      					// CHECK
      					registers[idata[11:7]] <= registers[idata[19:15]] < registers[idata[24:20]] ? 1 : 0;
      				end
      				
      				3'b100: begin
      					// XOR
      					registers[idata[11:7]] <= registers[idata[19:15]] ^ registers[idata[24:20]];
      				end
      				
      				3'b101: begin
		  				if(idata[31:27] == 00000)
		  					// SRL
		  					registers[idata[11:7]] <= registers[idata[19:15]] >> registers[idata[24:20]];
		  				else if (idata[31:27] == 01000)
		  					registers[idata[11:7]] <= registers[idata[19:15]] >>> registers[idata[24:20]];
      				end
      				
      				3'b111: begin
      					// AND
      					registers[idata[11:7]] <= registers[idata[19:15]] & registers[idata[24:20]];
      				end
      			endcase
			end       			
        	
        	// Continue from LB	
        		  
        	endcase
        	
            iaddr <= iaddr + 4;
        end
    end

endmodule
