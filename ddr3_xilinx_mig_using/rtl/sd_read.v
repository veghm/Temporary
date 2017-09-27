
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    sd_read 
//////////////////////////////////////////////////////////////////////////////////
module sd_read(   input SD_clk,
						output reg SD_cs,
						output reg SD_datain,
						input  SD_dataout,
						
						output reg [7:0]mydata_o,
						output reg myvalid_o,
						output reg data_come,
						
						input init,
						
						output reg [3:0] mystate,
						output reg read_o
						
						
    );
	 

reg [7:0] rx;
reg en;
reg rx_valid;
reg [5:0] aa;	 
reg [21:0] cnt;

reg [31:0] sec;            //SD的sec地址

reg myen;

reg read_finish;
reg read_start;

reg [7:0] mydata;

reg [1:0] read_step;
reg [9:0] read_cnt;

reg [15:0] delay_cnt;

reg [47:0] CMD17; //CMD17的字节序列

reg [2:0] cnta,cntb;

reg [11:0] sec_size;

parameter idle=4'd0;
parameter read=4'd1;
parameter read_wait=4'd2;
parameter read_data=4'd3;
parameter read_done=4'd4;

parameter SEC_LEN=12'd3072;    //total sector size of one picture : 1024 * 768 * 2 /512

parameter SADDR=32'd32776;        //图片在SD卡的起始sector地址,第一副为16448,第二幅为19520
	 
always @(posedge SD_clk)
begin
	rx[0]<=SD_dataout;
	rx[7:1]<=rx[6:0];
end

//接收一个block读命令的应答数据
always @(posedge SD_clk)
begin
	if(!SD_dataout&&!en)begin rx_valid<=1'b0; aa<=1;en<=1'b1;end      //等待SD_dataout为低,SD_dataout为低,开始接收数据
   else if(en)	begin 
		if(aa<7) begin
			aa<=aa+1'b1; 
			rx_valid<=1'b0;
		end
		else begin
			aa<=0;
			en<=1'b0;
			rx_valid<=1'b1;             //接收完第8bit后,rx_valid信号开始有效
		end
	end
	else begin en<=1'b0;aa<=0;rx_valid<=1'b0;end
end

//block SD读流程
always @(negedge SD_clk)
if(!init)
	begin
		mystate<=idle;
		CMD17<={8'h51,8'h00,8'h00,8'h00,8'h00,8'hff};
		read_start<=1'b0;
		read_o<=1'b0;
		sec<=SADDR;
		sec_size<=0;
	end
else
	begin
	case(mystate)
		idle:	begin
				read_start<=1'b0;
				SD_cs<=1'b1;
				SD_datain<=1'b1;
				cnt<=22'd0;	
				if((read_o==1'b0) && (delay_cnt==10000))        //如果还没有把SD卡的图片存放到SDRAM中
					begin
						mystate<=read;
						read_o<=1'b0;
						CMD17<={8'h51,sec[31:24],sec[23:16],sec[15:8],sec[7:0],8'hff};
					end
				else begin
				   mystate<=idle;
					delay_cnt<=delay_cnt+1'b1;	
	         end	
		end
		read: begin                    //发送CMD17命令 (single Block Read)	
			   read_start<=1'b0;
			   if(CMD17!=48'd0) begin
					SD_cs<=1'b0;
					SD_datain<=CMD17[47];
					CMD17<={CMD17[46:0],1'b0};     //移位输出
					myen<=1'b0;
					cnt<=22'd0;									
				end
				else begin 
				   if(rx_valid) begin         //等待应答信号			
						cnt<=0;
						mystate<=read_wait;
					end
				end
		end
		read_wait: begin             //等待接收数据的起始位,低电平
		     if(read_finish)  begin
			     mystate<=read_done;
				  read_start<=1'b0;
			  end
			  else
			     read_start<=1'b1;				  
		end	
		read_done: begin               //读512个字节完成
			  read_start<=1'b0;
				if(cnt<22'd15) begin
					 SD_cs<=1'b1;
					 SD_datain<=1'b1;
					 cnt<=cnt+1'b1;
				 end
				 else begin 
				    cnt<=0;
					 if (sec_size<SEC_LEN) begin            //如果整幅图像还未读完 
 					    read_o<=1'b0;
                   sec <= sec + 1'b1;
						 sec_size <= sec_size +1'b1;
						 mystate<=idle;
					 end	 
					 else	begin	 
					    read_o<=1'b1;
						 mystate<=idle;
					 end	 

				end
		end
		default:mystate<=0;
		endcase		
	end

//接收SD数据	
always @(posedge SD_clk)
begin
	if(!init)begin
		myvalid_o<=1'b0;
		mydata_o<=0;
		mydata<=0;
		read_step<=2'b00;
		read_finish<=1'b0;
		data_come<=1'b0;
	end
	else begin
		case (read_step) 
		2'b00: begin
			cntb<=0;
			read_cnt<=0;
			read_finish<=1'b0;
		   if((read_start==1'b1)&(!SD_dataout)) begin     //接收到数据开始信号
				  read_step<=2'b01;
				  data_come<=1'b1;
			end	  
			else 
				  read_step<=2'b00;
		end
		2'b01: begin             //接收512个bytes
			if(read_cnt<512)	begin
			   if(cntb<7)	begin
				      myvalid_o<=1'b0;
					   mydata<={mydata[6:0],SD_dataout};
					   cntb<=cntb+1'b1;
						data_come<=1'b0;
				 end
				 else begin
						myvalid_o<=1'b1;            //一个byte数据有效
						mydata_o<={mydata[6:0],SD_dataout};
						cntb<=0;
						read_cnt<=read_cnt+1'b1;
						data_come<=1'b0;
				  end
			 end
			 else begin 
				   read_finish<=1'b1;
					read_step<=2'b00;
					myvalid_o<=1'b0;
					data_come<=1'b0;
			 end
		end
		default:read_step<=2'b00;
		endcase	
    end
end	 

endmodule

