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


module SingleCount
#(
    parameter S_WIDTH = 8 //width of single symbol
)(
    input mode, //high state turns module ON
    input [S_WIDTH-1:0]alphabet_symbol, //compared alphabet symbol
    input [S_WIDTH-1:0]symbol_in, //compared text symbol
    input [7:0]symbol_cnt_in, //counter input value
    output [7:0]symbol_cnt_out //counter output value
);

//porownanie wartosci symbolu wejsciowego i alfabetu i ewentualna inkrementacja licznika
assign symbol_cnt_out = mode && (alphabet_symbol == symbol_in) ? symbol_cnt_in + 1 : symbol_cnt_in;

endmodule
