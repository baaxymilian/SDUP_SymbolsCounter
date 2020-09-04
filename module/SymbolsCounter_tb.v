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

module SymbolsCounter_tb();

reg clk;
reg reset;
reg start;
reg mode, end_flag;
reg [7:0]text[255:0]; //input text memory
reg [7:0]alphabet[27:0] = {8'h00, 8'h20, 8'h61, 8'h62, 8'h63, 8'h64, 8'h65, 8'h66, 8'h67, 8'h68,
    8'h69, 8'h6A, 8'h6B, 8'h6C, 8'h6D, 8'h6E, 8'h6F, 8'h70, 8'h71, 8'h72, 8'h73, 8'h74, 8'h75, 8'h76, 8'h77, 8'h78, 8'h79, 8'h7A};
reg [7:0]in;

wire [7:0]count_array; //output vector for symbol occurences
wire [7:0]symbol_out;
wire ready_out;

integer iterator; //count occurences and iterate through symbols

// Reset stimulus
initial
begin
    reset = 1'b1;
    #50 reset = 1'b0;
end

// Clocks stimulus
initial
begin
    clk = 1'b0; //set clk to 0
    clk = 1'b1;
end
always
begin
    #5 clk = ~clk; //toggle clk every 5 time units
end

initial
begin
    iterator = 0;
    start = 0;
    end_flag = 0;
    mode = 0;
    in <= alphabet[iterator];
    text <= "";
    text <= "lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua";
end

always @ (posedge reset)
begin
    #10
    iterator = 0;
    start = 0;
    end_flag = 0;
    mode = 0;
    in <= alphabet[iterator];
    reset = 1'b0;
    #50 start = 1;
end

always @ (posedge ready_out)
begin
    if (reset == 1'b0)
    begin
        start = ~start; //
        #20
        start = ~start;
        if(end_flag == 1'b0)
        begin
            if(mode == 1'b0) //insert alphabet to processor memory
            begin
                if(alphabet[iterator] != 8'h00)
                begin
                    iterator = iterator + 1;
                    in <= alphabet[iterator];
                end
                else
                begin
                    mode <= 1;
                    iterator = 0;           
                end       
            end 
            else //mode == 1, input text
            begin
                if(text[iterator] != 8'h00)
                begin
                    in <= text[iterator];
                    iterator = iterator + 1;
                end
                else
                begin
                    end_flag <= 1;
                    iterator = 0;
                end
            end //mode
        end
        else //end_flag == 1
        begin
            $display("SYMBOL: '%c' OCCURENCES: %d", symbol_out, count_array);
            if(symbol_out == 8'h00)
            begin
                end_flag = 1'b0;
                $display("SUM: %d", iterator);
                reset = 1'b1;
            end
            iterator = iterator + count_array;
        end  //end_flag
    end
    else // reset == 0
    begin
        iterator = 0;   
    end //reset
end

//Instantiate tested module
SymbolsCounter SymbolsCounter_inst ( 
    .clock(clk), 
    .reset, 
    .start(start), 
    .mode, 
    .end_flag,
    .symbol_in(in),
    .count_array,
    .symbol_out,
    .ready_out);

endmodule
