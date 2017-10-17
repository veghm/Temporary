`timescale 1ns / 1ps
module eeprom_test_tb();

// iic interface
reg CLK_50M;
reg RSTn;
wire [3:0]LED;
wire SCL;         //EEPROM IIC clock
wire SDA ;           //EEPROM IIC data
// other signal
wire read_SDA; 
reg link_flag;
reg	write_SDA;

eeprom_test eeprom_test_inst
(
    .CLK_50M(CLK_50M),
	.RSTn	(RSTn	),
	.LED	(LED	),
	.SCL	(SCL    ),          //EEPROM IIC clock
	.SDA	(SDA    )            //EEPROM IIC data
);
/*
*	bidirection SDA 
*/
assign read_SDA = !link_flag ? SDA : 1'bz;
assign SDA = link_flag ? write_SDA : 1'bz; 

always @(posedge CLK_50M or negedge RSTn)begin
	link_flag <= 1'b0;
end
always @(posedge CLK_50M or negedge RSTn)begin
	write_SDA <= 1'b0;
end
/*
*	COLCK&reset set
*/
initial begin
	CLK_50M = 0;
	RSTn    = 0;
	forever begin #10; CLK_50M = ~CLK_50M; end 
end
initial begin
	reset_task(2000);
end	 
/*
*
*/

/*
*	task reset
*/	 
task reset_task;
input [15:0]delay_time; 
begin
	RSTn <= 1'b0;
	#(delay_time) RSTn = 1'b1;
end
endtask

endmodule
  