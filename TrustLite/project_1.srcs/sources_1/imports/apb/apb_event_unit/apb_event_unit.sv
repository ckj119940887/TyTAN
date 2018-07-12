/* debug_zs
`include "defines_event_unit.sv"
*/

//debug_zs 替换`include "defines_event_unit.sv"
// total number of address space reserved for the apb_event_unit
`define ADR_MAX_ADR				'd2 // number of bits needed to access all subunits

`define IRQ						2'b00
`define EVENT					2'b01
`define SLEEP					2'b10

// number of registers per (interrupt, event) service unit - 8 regs in total
`define REGS_MAX_IDX			'd3 // number of bits needed to access all registers
`define REGS_MAX_ADR				'd2

`define REG_ENABLE 				2'b00
`define REG_PENDING      		2'b01
`define REG_SET_PENDING			2'b10
`define REG_CLEAR_PENDING		2'b11

`define REGS_SLEEP_MAX_IDX		'd1

`define REG_SLEEP_CTRL        	2'b0
`define REG_SLEEP_STATUS		2'b1

`define SLEEP_ENABLE			1'b0
`define SLEEP_STATUS 			1'b0


module apb_event_unit
#(
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(
    input  logic                      clk_i, //clk bypass for synch ff
    input  logic                      HCLK,
    input  logic                      HRESETn,
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,

    // irq processing
    input  logic               [31:0] irq_i,
    input  logic               [31:0] event_i,
    output logic               [31:0] irq_o,

    // Sleep control
    input  logic                      fetch_enable_i,
    output logic                      fetch_enable_o,
    output logic                      clk_gate_core_o, // output to core's clock gate to
    input  logic                      core_busy_i
);

    logic [31:0] events;

    // one hot encoding
    logic [2:0] psel_int, pready, pslverr;

    logic [1:0] slave_address_int;
    // output, internal wires
    logic [2:0] [31:0] prdata;

    logic fetch_enable_ff1, fetch_enable_ff2, fetch_enable_int;

    assign fetch_enable_o =  fetch_enable_ff2 & fetch_enable_int;

    assign slave_address_int = PADDR[`ADR_MAX_ADR + `REGS_MAX_ADR + 1:`REGS_MAX_ADR + 2];

    // address selector - select right peripheral
    always_comb
    begin
        psel_int = 3'b0;
        psel_int[slave_address_int] = PSEL;
    end

    // output mux
    always_comb
    begin
        if (psel_int != 2'b00)
        begin
            PRDATA  = prdata[slave_address_int];
            PREADY  = pready[slave_address_int];
            PSLVERR = pslverr[slave_address_int];
        end
        else
        begin
            PRDATA  = '0;
            PREADY  = 1'b1;
            PSLVERR = 1'b0;
        end
    end

    // interrupt unit
    generic_service_unit
    #(
        .APB_ADDR_WIDTH ( APB_ADDR_WIDTH )  //APB slaves are 4KB by default
    )
    i_interrupt_unit
    (
        .HCLK     ( HCLK        ),
        .HRESETn  ( HRESETn     ),
        .PADDR    ( PADDR       ),
        .PWDATA   ( PWDATA      ),
        .PWRITE   ( PWRITE      ),
        .PSEL     ( psel_int[0] ),
        .PENABLE  ( PENABLE     ),
        .PRDATA   ( prdata[0]   ),
        .PREADY   ( pready[0]   ),
        .PSLVERR  ( pslverr[0]  ),

        .signal_i ( irq_i       ), // generic signal could be an interrupt or an event
        .irq_o    ( irq_o       )
    );


    // event unit
    generic_service_unit
    #(
        .APB_ADDR_WIDTH ( APB_ADDR_WIDTH )  //APB slaves are 4KB by default
    )
    i_event_unit
    (
        .HCLK     ( HCLK        ),
        .HRESETn  ( HRESETn     ),
        .PADDR    ( PADDR       ),
        .PWDATA   ( PWDATA      ),
        .PWRITE   ( PWRITE      ),
        .PSEL     ( psel_int[1] ),
        .PENABLE  ( PENABLE     ),
        .PRDATA   ( prdata[1]   ),
        .PREADY   ( pready[1]   ),
        .PSLVERR  ( pslverr[1]  ),

        .signal_i ( event_i     ), // generic signal could be an interrupt or an event
        .irq_o    ( events      )
    );


    // sleep unit
    sleep_unit
    #(
        .APB_ADDR_WIDTH ( APB_ADDR_WIDTH )  //APB slaves are 4KB by default
    )
    i_sleep_unit
    (
        .HCLK            ( HCLK             ),
        .HRESETn         ( HRESETn          ),
        .PADDR           ( PADDR            ),
        .PWDATA          ( PWDATA           ),
        .PWRITE          ( PWRITE           ),
        .PSEL            ( psel_int[2]      ),
        .PENABLE         ( PENABLE          ),
        .PRDATA          ( prdata[2]        ),
        .PREADY          ( pready[2]        ),
        .PSLVERR         ( pslverr[2]       ),

        .irq_i           ( |irq_o           ), // interrupt signal - for sleep ctrl
        .event_i         ( |events          ), // event signal - for sleep ctrl
        .core_busy_i     ( core_busy_i      ), // check if core is busy
        .fetch_en_o      ( fetch_enable_int ),
        .clk_gate_core_o ( clk_gate_core_o  ) // output to core's clock gate to
                                              //signal in order to give the core enough time after wakeup to catch the signal
    );

    // fetch enable synchronizer part
    always_ff @(posedge clk_i, negedge HRESETn)
    begin
        if(~HRESETn)
        begin
            fetch_enable_ff1   <= 1'b0;
            fetch_enable_ff2   <= 1'b0;
        end
        else
        begin
            fetch_enable_ff1  <= fetch_enable_i;
            fetch_enable_ff2  <= fetch_enable_ff1;
        end
    end

endmodule
