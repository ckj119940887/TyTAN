`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/10/2018 02:23:35 PM
// Design Name: 
// Module Name: ea_mpu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ea_mpu
    #(
        parameter RAM_SIZE      = 32768,
        parameter ADDR_WIDTH    = $clog2(RAM_SIZE),
        parameter DATA_WIDTH    = 32,
        parameter VALID_ADDR_WIDTH = 32
    )(
        input logic                     clk,
        input logic                     rst_n,
    
        //instr_addr from IF stage
        input logic  [VALID_ADDR_WIDTH-1:0]   if_instr_addr,
        input logic  [VALID_ADDR_WIDTH-1:0]   ex_data_addr,
        
        //from ram_mux
        input logic                     ram_mux_req,
        input logic                     ram_mux_gnt,
        output logic                    ram_mux_valid,
    
        //for validation
        input logic                     en_i,
        input logic  [ADDR_WIDTH-1:0]   addr_i,
        input logic                     we_i,
        input logic  [DATA_WIDTH/8-1:0]  be_i,
        output logic [DATA_WIDTH-1:0]    rdata_o,
        input logic  [DATA_WIDTH-1:0]    wdata_i,
        
        //to ram
        output logic                    ram_en_o,
        output logic [ADDR_WIDTH-1:0]   ram_addr_o,
        output logic                    ram_we_o,
        output logic [DATA_WIDTH/8-1:0]  ram_be_o,
        input  logic [DATA_WIDTH-1:0]    ram_rdata_i,
        output logic [DATA_WIDTH-1:0]    ram_wdata_o
    );
    
    //for validation
    logic                    reg_en;
    logic [ADDR_WIDTH-1:0]   reg_addr;
    logic                    reg_we;
    logic [DATA_WIDTH/8-1:0] reg_be;
    logic [DATA_WIDTH-1:0]   reg_wdata;                   
    
    logic                    judge_valid;
    logic                    judge_result;
    logic  [VALID_ADDR_WIDTH-1:0]  judge_data_addr;
    logic  [VALID_ADDR_WIDTH-1:0]  judge_instr_addr;
    logic                    judge_req;
    
    
    enum logic [1:0] {IDLE, VALIDATION, LEGAL, ILLEGAL} filter_cs;

    
    always_ff@(posedge clk, negedge rst_n)
    begin
        if(rst_n == 1'b0)
        begin
            filter_cs       <= IDLE;
        end
        else
        begin
            //access_valid    <= 1'b1;
            
            
            unique case(filter_cs)
            IDLE:
            begin
                if(ram_mux_req && ram_mux_gnt)
                begin
                   
                    //save the state of CPU
                    reg_en <= en_i;
                    reg_addr <= addr_i;
                    reg_we <= we_i;
                    reg_be <= be_i;
                    reg_wdata <= wdata_i; 
                
                    judge_data_addr  <= ex_data_addr;       //current data addr
                    judge_instr_addr <= if_instr_addr - 4;  //current PC
                    judge_req        <= 1'b1;
                    
                    ram_mux_valid   <= 1'b0;
                    
                    filter_cs        <= VALIDATION;
                end
            end
            VALIDATION:
            begin
                ///filter_cs <= LEGAL;   
                if(judge_valid == 1'b1)
                begin
                    if(judge_result == 1'b1)
                        filter_cs <= LEGAL;
                    else
                        filter_cs <= ILLEGAL;
                end
            end
            LEGAL:
            begin
                judge_req       <= 1'b0;
                
                ram_en_o     <= reg_en;
                ram_addr_o   <= reg_addr;
                ram_we_o     <= reg_we;
                ram_be_o     <= reg_be;
                rdata_o      <= ram_rdata_i;
                ram_wdata_o  <= reg_wdata;
                
                ram_mux_valid   <= 1'b1;
                
                filter_cs       <= IDLE;
                   
            end
            ILLEGAL:
            begin
                judge_req    <= 1'b0;
                $display("hello world\n");
                filter_cs    <= IDLE;
            end
            endcase
            
        end
    end
    
    
    ea_mpu_ram ea_mpu_ram_i
    (
         .clk(clk),
         .rst_n(rst_n),
         .en_i(judge_req),
           
           //the code address and data address need to judge
         .instr_addr_i(judge_instr_addr),
         .data_addr_i(judge_data_addr),
           
           //updating the item in code range and data range
         .we_i(we_i),
         .wdata_i(wdata_i),
           
           //the result of comparasion in code range and data range
         .valid(judge_valid),
         .result(judge_result)
    );
    
    
    
    
endmodule
