`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/10/2018 02:24:41 PM
// Design Name: 
// Module Name: ea_mpu_ram
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


module ea_mpu_ram
    #(
        parameter ADDR_WIDTH    = 32,
        parameter DATA_WIDTH    = 32,
        parameter REGION_NUM    = 32,
        parameter COUNTER_WIDTH = $clog2(REGION_NUM),
        parameter INSTR_START   = 32'h00107E00,
        parameter INSTR_END     = 32'h00107E80,
        parameter DATA_START    = 32'h00107F00,
        parameter DATA_END      = 32'h00107F80  
    )(
        input logic                     clk,
        input logic                     rst_n,
        
        input  logic                    en_i,
        
        //the code address and data address need to judge
        input  logic [ADDR_WIDTH-1:0]   instr_addr_i,
        input  logic [ADDR_WIDTH-1:0]   data_addr_i,
        
        //updating the item in code range and data range
        input  logic                    we_i,
        input  logic [DATA_WIDTH-1:0]   wdata_i,
        
        //the result of comparasion in code range and data range
        output logic valid,
        output logic result
                   
    );
    
    logic [ADDR_WIDTH-1:0]     instr_start[REGION_NUM];
    logic [ADDR_WIDTH-1:0]     instr_end[REGION_NUM];
    logic [ADDR_WIDTH-1:0]     data_start[REGION_NUM];
    logic [ADDR_WIDTH-1:0]     data_end[REGION_NUM];
    
    logic [COUNTER_WIDTH-1:0] counter;
    
    logic outcome_instr_start;
    logic outcome_instr_end;
    logic outcome_data_start;
    logic outcome_data_end;
    
    //FSM
    enum logic [1:0] {IDLE, COMPARISON, VALIDATION, UPDATE} ea_mpu_ram_cs;
    
    //Combination logic for validation
    enum logic {LEGAL, ILLEGAL} validation_state;
 
    
    /*
    initial begin
        counter <= 4'b0010; 
    
        instr_start[0] <= 32'h00008000; instr_end[0] <= 32'h00008499;
        instr_start[1] <= 32'h00008500; instr_end[1] <= 32'h00009000;
        
        
        data_start[0] <= 32'h00100200; data_end[0] <= 32'h00100900;
        data_start[1] <= 32'h00100A00; data_end[1] <= 32'h00101000;
        
    end
    */
    
    initial begin
         instr_start[0] <= 32'h00008000; instr_end[0] <= 32'h00008499;
         data_start[0] <= 32'h00107E00; data_end[0] <= 32'h00108000;
    end
      
    always @(posedge clk, negedge rst_n)
    begin
        
        if (rst_n == 1'b0)
        begin
            ea_mpu_ram_cs   <= IDLE;
            counter         <= 1;
            outcome_instr_start <= 0;
            outcome_instr_end   <= 0;
            outcome_data_start  <= 0;
            outcome_data_end    <= 0;
        end
        else
        begin
            unique case(ea_mpu_ram_cs)
            IDLE:
            begin
                valid  <= 0;
                result <= 0;
                
                if(outcome_instr_start && outcome_instr_end && outcome_data_start && outcome_data_end)
                begin
                    counter <= counter + 1;
                    outcome_instr_start <= 0;
                    outcome_instr_end   <= 0;
                    outcome_data_start  <= 0;
                    outcome_data_end    <= 0;
                end
                
                if(en_i)
                begin
                    ea_mpu_ram_cs <= COMPARISON;
                end
               
            end
            
            COMPARISON:
            begin
                validation_state <= ILLEGAL;
                
                for(int i = 0; i < counter; i++)
                begin
                    if( (instr_addr_i[ADDR_WIDTH-1:0] >= instr_start[i]) &&
                        (instr_addr_i[ADDR_WIDTH-1:0] <= instr_end[i])   &&
                        (data_addr_i[ADDR_WIDTH-1:0]  >= data_start[i])  &&
                        (data_addr_i[ADDR_WIDTH-1:0]  <= data_end[i])       )
                        validation_state <= LEGAL;
                end
                
                ea_mpu_ram_cs <= VALIDATION;
            end
            
            VALIDATION:
            begin
                if(validation_state == LEGAL)
                begin
                    result <= 1;
                    valid  <= 1;
                    
                    if(we_i)
                    begin
                        if( (data_addr_i >= INSTR_START) && (data_addr_i < INSTR_START + 32'h80)  ||
                            (data_addr_i >= INSTR_END)   && (data_addr_i < INSTR_END + 32'h80)    ||
                            (data_addr_i >= DATA_START)  && (data_addr_i < DATA_START + 32'h80)   ||
                            (data_addr_i >= DATA_END)    && (data_addr_i < DATA_END + 32'h80) )
                            ea_mpu_ram_cs <= UPDATE;
                        else 
                            ea_mpu_ram_cs <= IDLE;
                    end
                    else 
                    begin
                        ea_mpu_ram_cs <= IDLE;
                    end
                end
                else if(validation_state == ILLEGAL)
                begin
                    result <= 0;
                    valid  <= 1;
                    ea_mpu_ram_cs <= IDLE;
                end
            end
            
            UPDATE:
            begin
                if(we_i)
                begin
                    
                    if( (data_addr_i >= INSTR_START) && (data_addr_i < INSTR_START + 32'h80) )
                    begin
                        instr_start[counter] <= wdata_i;
                        outcome_instr_start <= 1;
                    end
                    
                    if( (data_addr_i >= INSTR_END) && (data_addr_i < INSTR_END + 32'h80) )
                    begin
                        instr_end[counter] <= wdata_i;
                        outcome_instr_end <= 1;
                    end
                    
                    if( (data_addr_i >= DATA_START) && (data_addr_i < DATA_START + 32'h80) )
                    begin
                        data_start[counter] <= wdata_i;
                        outcome_data_start <= 1;
                    end
                    
                    if( (data_addr_i >= DATA_END) && (data_addr_i < DATA_END + 32'h80) )
                    begin
                        data_end[counter] <= wdata_i;
                        outcome_data_end <= 1;
                    end
                    
                    ea_mpu_ram_cs <= IDLE;
                end
            end
            
            endcase
        end
       
    end
    
endmodule
