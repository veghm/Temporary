module eeprom(
	input	i_CLK_50M,
	input	RSTn,
	input	i_SCL
	input	i_SDA_in,
	output	o_SDA_out,
);
parameter F250K = 9'd200;                //250Khz的时钟分频系数

//write eeprom 
always@(i_SDA_in)

endmodule