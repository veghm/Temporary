module sys_init(
	input clk_in,
	input RSTn,
	output o_clk_out1,
	//output o_clk_out2,
	output RST_n
);
wire w_LOCKED;
wire w_clk_out1;
reg sys_rst,sysn_rst;

//resrt signal procss
always @(posedge w_clk_out1 or negedge RSTn)
	if(!RSTn)  sys_rst <= 1'b0;
	else sys_rst <= 1'b1;
always @(posedge w_clk_out1 or negedge RSTn)
	if(!RSTn)  sysn_rst <= 1'b0;
	else sysn_rst <= sys_rst; 
assign RST_n = sysn_rst;

assign o_clk_out1 = w_clk_out1;
//assign o_clk_out2 = w_clk_out2;
pll_ip pll_ip_inst(
// Clock in ports
	.CLK_IN1(clk_in),
  // Clock out ports
	.CLK_OUT1(w_clk_out1), 	//50MHZ
	.CLK_OUT2(w_clk_out2),	//100MHZ
  // Status and control signals
	.RESET(!RSTn),
	.LOCKED(w_LOCKED)
 );
/*
ODDR2 #( 
            .DDR_ALIGNMENT("NONE"),          // Sets output alignment to "NONE", "C0" or "C1" 
            .INIT(1'b0),                                // Sets initial state of the Q output to 1'b0 or 1'b1 
            .SRTYPE("SYNC")                          // Specifies "SYNC" or "ASYNC" set/reset 
              ) ODDR2_inst ( 
            .Q(o_clk_out2),                                // 1-bit DDR output data 
            .C0(w_clk_out2),                          // 1-bit clock input 
            .C1(~w_clk_out2),                        // 1-bit clock input 
            .CE(1'b1),                                    // 1-bit clock enable input 
            .D0(1'b1),                                    // 1-bit data input (associated with C0) 
            .D1(1'b0),                                    // 1-bit data input (associated with C1) 
            .R(1'b0),                                      // 1-bit reset input 
            .S(1'b0)                                        // 1-bit set input 
        ); 
*/
endmodule