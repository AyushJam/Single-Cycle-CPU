/*
	Assignment 3: Single Cycle CPU
	EE2003: Computer Organization
    July-November 2022

	Author: Ayush Jamdar EE20B018
	Date started: September 22, 22
	Last Modified: October 8, 22
	
	Abstract: To implement all the instructions of the 
		RISC-V 32I instruction set.
		
	References 
	1. https://en.wikichip.org/wiki/risc-v/registers
	2. https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html
	
	Single Cycle CPU: 
    1. Implementing Branch Instructions
    2. ALU Instructions
    3. Load Store
*/

module cpu (
    input clk, 
    input reset,
    output  [31:0] iaddr,
    input   [31:0] idata,
    output  [31:0] daddr,
    input   [31:0] drdata,
    output  [31:0] dwdata,
    output  [3:0] dwe
);
    reg [31:0] daddr;
    reg [31:0] dwdata;
    reg [3:0]  dwe;
    
    // Create a register file
    // 32 registers, each 32-bit wide
    // to infer a D-FF, used the _d and _q regs
    // registers[which register][which bit of register]
   	reg [31:0] registers_d [31:0];
   	reg [31:0] registers_q [31:0];
    reg [31:0] pc_q;
    reg [31:0] pc_d;
	integer i, k;
	
	wire [4:0] rs1, rs2, rd;
	wire [11:0] imm;
	
	assign rs1  = idata[19:15];  // source register 1
	assign rs2  = idata[24:20];  // source register 2
    assign rd   = idata[11:7];    // destination register
	assign imm  = idata[31:20];  // immediate data in instruction
    assign iaddr = pc_q;        // instruction memory address
	
    always @(posedge clk) begin
        if (reset) begin
            pc_q 	<= 0;
            // pc_d    <= 0;
            // idk why this statement if not removed gives error
            daddr 	<= 0;
            dwdata 	<= 0;
            dwe		<= 0;
            // clear all registers
            for (i = 0; i < 32; i = i + 1) begin
            	// registers_d[i][31:0]	<= 32'b0;
                // idk why this statement if not removed gives error
            	registers_q[i][31:0]	<= 32'b0;
            end
            
        end 
        else begin			        	
			for (i = 0; i < 32; i = i + 1) begin
                if (i == 0)     registers_q[i] <= 32'b0;
                else            registers_q[i] <= registers_d[i];
			end
			pc_q <= pc_d;
        end
    end
    
    always@(*) begin
    	// All instructions except dmem Load are combinational in a single cycle CPU.
    	// default for all registers
    	for (i = 0; i < 32; i = i + 1) begin
           	registers_d[i]	= registers_q[i];
        end
    	
        // default program counter increment
        pc_d = pc_q + 4; 

        // the above default assignments may get updated in the following computation

    	// Start with decoding the instruction
    	case (idata[6:0])
    		7'b0110111: begin 
    			// U-Type
	    		// LUI
	    		if (rd != 0) registers_d[rd] = ({idata[31:12], 12'b0});
                else ;
	    	end
	    	
	    	7'b0010111: begin
	    		// AUIPC - add upper immediate to pc
	    		if (rd != 0) registers_d[rd] = iaddr + (idata[31:12] << 12);
                else ;
            end
	    	
	    	7'b0010011: begin
                // Immediate instructions
                case (idata[14:12])
                    3'b000: begin
                        // ADDI - add immediate
                        if (rd != 0) registers_d[rd] = registers_q[rs1] + {{20{idata[31]}}, imm};
                        else ;
                    end
                        
                    3'b010: begin 
                        // SLTI - set less than immediate
                        if (rd != 0) registers_d[rd] = ($signed(registers_q[rs1]) < $signed({{20{idata[31]}}, imm})) ? 1 : 0;
                        else ;
                    end
                        
                    3'b011: begin 
                        // SLTIU - set less than immediate (unsigned) 
                        if (rd != 0) registers_d[rd] = (registers_q[rs1] < {{20{idata[31]}}, imm}) ? 1 : 0;
                        else ;
                    end
                        
                    3'b100: begin
                        // XORI - xor immediate      
                        if (rd != 0) registers_d[rd] = (registers_q[rs1]) ^ {{20{idata[31]}}, imm};
                        else ;
                    end
                        
                    3'b110: begin 
                        // ORI - or immediate
                        if (rd != 0) registers_d[rd] = registers_q[rs1] | {{20{idata[31]}}, imm};
                        else ;
                    end				
                        
                    3'b111: begin
                        // ANDI - and immediate
                        if (rd != 0) registers_d[rd] = registers_q[rs1] & {{20{idata[31]}}, imm};
                        else ;
                    end
                        
                    3'b001: begin
                        // SLLI - shift logical left
                        if (rd != 0) registers_d[rd] = registers_q[rs1] << rs2;
                        else ;
                    end
                        
                    3'b101: begin
                        if (idata[31:27] == 00000) 
                            // SRLI - shift logical right
                            if (rd != 0) registers_d[rd] = registers_q[rs1] >> rs2;
                            else ;
                        else if (idata[31:27] == 01000)
                            // SRAI - shift right arithmetic
                            if (rd != 0) registers_d[rd] = registers_q[rs1] >>> rs2;
                            else ;
                    end
                endcase
		    end
		    
		    7'b0110011: begin
                case(idata[31:25])
                    7'b000_0000: begin
                        case(idata[14:12])
                            3'b000: begin // ADD
                                if (rd != 0) registers_d[rd] = registers_q[rs1] + registers_q[rs2];
                                else ;
                            end
                            3'b001: begin  // SLL
                                if (rd != 0) registers_d[rd] = registers_q[rs1] << registers_q[rs2][4:0];
                                else ;
                            end
                            3'b010: begin  // SLT
                                if (rd != 0) registers_d[rd] = ($signed(registers_q[rs1]) < ($signed(registers_q[rs2]))) ? 1 : 0;
                                else ;
                            end
                            3'b011: begin  // SLTU
                                if (rd != 0) registers_d[rd] = (registers_q[rs1] < registers_q[rs2]) ? 1 : 0;
                                else ;
                            end
                            3'b100: begin  // XOR
                                if (rd != 0) registers_d[rd] = registers_q[rs1] ^ registers_q[rs2];	
                                else ;
                            end
                            3'b101: begin  // SRL
                                if (rd != 0) registers_d[rd] = registers_q[rs1] >> registers_q[rs2][4:0];
                                else ;
                            end
                            3'b110: begin  // OR
                                if (rd != 0) registers_d[rd] = registers_q[rs1] | registers_q[rs2];
                                else ;
                            end
                            3'b111: begin  // AND
                                if (rd != 0) registers_d[rd] = registers_q[rs1] & registers_q[rs2];
                                else ;
                            end
                        endcase
                    end
                    7'b010_0000: begin
                        case(idata[14:12])
                            3'b000: begin // SUB
                                if (rd != 0) registers_d[rd] = registers_q[rs1] - registers_q[rs2]; 
                                else ;
                            end
                            3'b101: begin // SRA
                                if (rd != 0) registers_d[rd] = registers_q[rs1] >>> registers_q[rs2][4:0];
                                else ;
                            end
                        endcase
                    end
                endcase
			end
			
			7'b0000011: begin
                // here imm is the offset given in instruction
                case(idata[14:12])
                    3'b000: begin
                        // LB - load byte
                        daddr = registers_q[rs1] + {{20{idata[31]}}, imm};
                        if (rd != 0) registers_d[rd] = {{24{drdata[7]}}, drdata[7:0]};
                        else ;
                        // as soon as data address is given, it is assumed that the data will be obtained
                    end
                    
                    3'b001: begin
                        // LH - load half word
                        daddr = registers_q[rs1] + {{20{idata[31]}}, imm};
                        if (rd != 0) registers_d[rd] = {{16{drdata[7]}}, drdata[15:0]};
                        else ;
                    end
                    
                    3'b010: begin
                        // LW - load word
                        daddr = registers_q[rs1] + {{20{idata[31]}}, imm};
                        if (rd != 0) registers_d[rd] = drdata;
                        else ;
                    end		
                    
                    3'b100: begin
                        // LBU - load byte unsigned
                        daddr = registers_q[rs1] + {{20{idata[31]}}, imm};
                        if (rd != 0) registers_d[rd] = {{24{1'b0}}, drdata[7:0]};
                        else ;
                        // CHECK
                    end
                    
                    3'b101: begin
                        // LHU - load halfword unsigned
                        daddr = registers_q[rs1] + {{20{idata[31]}}, imm};
                        if (rd != 0) registers_d[rd] = {{16{1'b0}}, drdata[15:0]};
                        else ;
                    end
                endcase
		    end
		    
		    7'b0100011: begin
                case(idata[14:12])
                    3'b000: begin
                        // SB - store byte in lower 8 bits of memory
                        daddr 	= registers_q[rs1] + {{20{idata[31]}}, {idata[31:25], rd}};
                        dwe 	= 1'b1 << daddr[1:0];
                        dwdata 	= {{24{1'b0}}, registers_q[rs2][7:0]};
                    end
                    // imm = imm rd = rd
                    3'b001: begin
                        // SH - store halfword in lower 16 bits of memory
                        daddr 	= registers_q[rs1] + {{20{idata[31]}}, {idata[31:25], rd}};
                        dwe 	= daddr[1] ? 4'b1100 : 4'b0011;
                        dwdata 	= {{16{1'b0}}, registers_q[rs2][15:0]};
                    end
                    
                    3'b010: begin
                        // SW - store word
                        dwe 	= 4'b1111;
                        daddr 	= registers_q[rs1] + {{20{idata[31]}}, {idata[31:25], rd}};
                        dwdata 	= registers_q[rs2];
                    end		    			
                endcase
		    end

            7'b1101111: begin
                // JAL - jump
                if (rd != 0) registers_d[rd] = pc_q + 4;
                else ;
                pc_d = pc_q + {{12{idata[31]}}, idata[19:12], idata[20], idata[30:21], 1'b0};
            end

            7'b1100111: begin
                // JALR - jump
                if (rd != 0) registers_d[rd] = pc_q + 4;
                else ;
                pc_d = (registers_q[rs1] + ({{20{idata[31]}}, idata[31:20]}) & (~(32'b1)));
            end

            7'b1100011: begin
                case(idata[14:12])
                    3'b000: begin
                        // BEQ - branch if equal
                        if (registers_q[rs1] == registers_q[rs2]) begin
                            pc_d = pc_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0};
                        end 
                    end

                    3'b001: begin
                        // BNE - branch if not equal
                        if (registers_q[rs1] != registers_q[rs2]) begin
                            pc_d = pc_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0};
                        end
                    end

                    3'b100: begin
                        // BLT - branch if less than
                        if ((registers_q[rs1]) < $signed(registers_q[rs2])) begin
                            pc_d = pc_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0};
                        end
                    end 

                    3'b101: begin
                        // BGE - branch if greater than
                        if ((registers_q[rs1]) >= $signed(registers_q[rs2])) begin
                            pc_d = pc_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0};
                        end
                    end

                    3'b110: begin
                        // BLTU - branch if less than unsigned
                        if (registers_q[rs1] < registers_q[rs2]) begin
                            pc_d = pc_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0};
                        end
                    end

                    3'b111: begin
                        // BGEU - branch if greater than unsigned 
                        if (registers_q[rs1] >= registers_q[rs2]) begin
                            pc_d = pc_q + {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0};
                        end
                    end
                endcase                   
            end
		endcase		
    end
endmodule 
