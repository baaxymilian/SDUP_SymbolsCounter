`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AGH UST
// Engineer: Bartosz Bryk
// 
// Create Date: IX 2020
// Design Name: SymbolsCounter
// Module Name: SingleCount
// Target Devices: Zybo
// Tool Versions: Vivado 2018.3
// 
//////////////////////////////////////////////////////////////////////////////////

module SymbolsCounter
#(
    parameter S_WIDTH = 8 //symbol width (for both alphabet and text)
)(
    input clock, //clock input
    input reset, //module reset - activated with high state
    input start, //initial signal for processing
    input mode, //input mode 0 - input alphabet, 1 - input text
    input end_flag, //enables output - activated with high state
    input [S_WIDTH-1:0]symbol_in, //input symbol (goes to alphabet or processor, depending on mode state)
    output reg [7:0]count_array, //how many given symbol was present in text
    output reg [S_WIDTH-1:0]symbol_out, //alphabet output symbol
    output ready_out //'processing ended' flag
);

reg [S_WIDTH-1:0]alphabet_memory[255:0]; //memory for storing alphabet symbols
reg [7:0]alphabet_counter = 0; //counter for alphabet symbols
reg [15:0]ready_cnt = 1; //decrementing counter 
reg ready = 0;

reg [7:0]result_memory[255:0]; //memory for storing the number of symbol occurrences
reg [7:0]result_counter = 1;
reg [7:0]output_counter = 0;

parameter S1 = 4'h01, S2 = 4'h02, S3 = 4'h03, S4 = 4'h04;
reg [2:0] state;

wire [S_WIDTH-1:0]memory_write; //auxiliary signal
wire [7:0]result_write[255:0]; //auxiliary signal

assign memory_write = symbol_in;

integer i = 0;
initial
    begin
    alphabet_counter <= 0;
    state <= S1;
    ready <= 0;
    for(i = 0; i < 256; i = i + 1)
    begin
        alphabet_memory[i] <= 0;
        result_memory[i] <= 0;
    end
end


always @(posedge clock)
begin
    if(reset == 1'b1) //reset section
    begin
        result_counter <= 0;
        alphabet_counter <= 0;
        output_counter <= 0;
        ready <= 0;
        state <= S1;
        for(i = 0; i < 256; i = i + 1)
        begin
            result_memory[i] <= 0;
            alphabet_memory[i] <= 0;
        end
    end
    else //insert symbols section state-machine
    begin
        case(state)
        S1:
            begin
                if(start == 1'b1) state <= S2; else state <= S1;
            end
        S2:
            begin
                ready <= 0;
                state <= S3;
            end        
        S3:
            begin
                if (end_flag != 1'b1)
                begin
                    case(mode)
                        0: 
                        begin //alphabet mode
                            alphabet_memory[alphabet_counter] <= memory_write;
                            alphabet_counter <= alphabet_counter + 1;
                            result_counter <= alphabet_counter + 1;
                        end
                        1: 
                        begin //text mode
                            for(i = 0; i < result_counter; i = i + 1)
                            begin
                                result_memory[i] <= result_write[i];
                            end
                        end
                    endcase
                end
                else // end_flag == 1'b1, output mode
                begin
                    if(result_counter > 0)
                    begin
                        count_array <= result_memory[output_counter];
                        symbol_out <= alphabet_memory[output_counter];
                        result_counter <= result_counter - 1;
                        output_counter <= output_counter + 1;
                    end
                    else
                    begin
                        result_counter <= output_counter;
                        output_counter <= 0;
                    end
                end
                ready <= 1;
                state <= S4;
            end
        S4:
            begin
                if(start == 1'b0) state <= S1; else state <= S4;
            end
        
        endcase
    end
end

assign ready_out = ready; // && (end_flag == 1) ? 1'b1 : 1'b0;

genvar j;
//generating processing blocks for each symbol in alphabet
generate for (j=0; j<256; j=j+1)
    begin: counter_loop
    SingleCount #(.S_WIDTH(S_WIDTH)) counter_step_0 (
        .mode(mode),
        .alphabet_symbol(alphabet_memory[j]),
        .symbol_in(symbol_in),
        .symbol_cnt_in(result_memory[j]),
        .symbol_cnt_out(result_write[j])
    );
    end
endgenerate

endmodule