module iic_com
(
     input CLK,
	 input RSTn,
	 
	 input [1:0] Start_Sig,             //read or write command
	 input [7:0] Addr_Sig,              //eeprom words address
	 input [7:0] WrData,                //eeprom write data
	 output [7:0] RdData,               //eeprom read data
	 output Done_Sig,                   //eeprom read/write finish
	 
	 output SCL,
	 inout SDA
	 
);

parameter F250K = 9'd200;                //250Khz��ʱ�ӷ�Ƶϵ��              
	 
reg [4:0]i;
reg [4:0]Go;
reg [8:0]C1;
reg [7:0]rData;
reg rSCL;
reg rSDA;
reg isAck;
reg isDone;
reg isOut;	
 
assign Done_Sig = isDone;
assign RdData = rData;
assign SCL = rSCL;
assign SDA = isOut ? rSDA : 1'bz;        //SDA�������ѡ��

//****************************************// 
//*             I2C��д�������            *// 
//****************************************// 
always @ ( posedge CLK or negedge RSTn )
	 if( !RSTn )  begin
			i <= 5'd0;
			Go <= 5'd0; 	
			C1 <= 9'd0;
			rData <= 8'd0;
			rSCL <= 1'b1;
			rSDA <= 1'b1;
			isAck <= 1'b1;
			isDone <= 1'b0;
			isOut <= 1'b1;
	 end
//I2C ����д	mode:BYTE WRITE 
	 else if( Start_Sig[0] )                     
	     case( i )
	//status start,write device addr,write word addr,write data,stop,isDone(flag)				    
		    0: //����IIC��ʼ�ź�
			 begin
					isOut <= 1;                         //SDA�˿����
					
					if( C1 == 0 ) rSCL <= 1'b1;
					else if( C1 == 200 ) rSCL <= 1'b0;       //SCL�ɸ߱��
							  
					if( C1 == 0 ) rSDA <= 1'b1; 
					else if( C1 == 100 ) rSDA <= 1'b0;        //SDA���ɸ߱�� 
							  
					if( C1 == 250 -1) begin C1 <= 9'd0; i <= i + 1'b1; end
					else C1 <= C1 + 1'b1;
			 end
					  
			 1: // Write Device Addr
			 begin rData <= {4'b1010, 3'b000, 1'b0}; i <= 5'd7; Go <= i + 1'b1; end         
				 
			 2: // Wirte Word Addr
			 begin rData <= Addr_Sig; i <= 5'd7; Go <= i + 1'b1; end
					
			 3: // Write Data
			 begin rData <= WrData; i <= 5'd7; Go <= i + 1'b1; end
	 
			 4: //����IICֹͣ�ź�
			 begin
			    isOut <= 1'b1;
						  
			    if( C1 == 0 ) rSCL <= 1'b0;
			    else if( C1 == 50 ) rSCL <= 1'b1;     //SCL���ɵͱ��       
		
				 if( C1 == 0 ) rSDA <= 1'b0;
				 else if( C1 == 150 ) rSDA <= 1'b1;     //SDA�ɵͱ��  
					 	  
				 if( C1 == 250 -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end
				 else C1 <= C1 + 1'b1; 
			 end
					 
			 5:
			 begin isDone <= 1'b1; i <= i + 1'b1; end       //дI2C ����
					 
			 6: 
			 begin isDone <= 1'b0; i <= 5'd0; end
	//send data(8bits) and wait ack(1bit)			 
			 7,8,9,10,11,12,13,14:                         //����Device Addr/Word Addr/Write Data
			 begin
			     isOut <= 1'b1;
				  rSDA <= rData[14-i];                      //��λ�ȷ���
					  
				  if( C1 == 0 ) rSCL <= 1'b0;
			     else if( C1 == 50 ) rSCL <= 1'b1;         //SCL�ߵ�ƽ100��ʱ������,�͵�ƽ100��ʱ������
				  else if( C1 == 150 ) rSCL <= 1'b0; 
						  
				  if( C1 == F250K -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end     //����250Khz��IICʱ��
				  else C1 <= C1 + 1'b1;
			 end
					 
			 15:                                          // waiting for acknowledge
			 begin
			     isOut <= 1'b0;                            //SDA�˿ڸ�Ϊ����
			     if( C1 == 100 ) isAck <= SDA;             //��ȡIIC ���豸��Ӧ���ź�
						  
				  if( C1 == 0 ) rSCL <= 1'b0;
				  else if( C1 == 50 ) rSCL <= 1'b1;         //SCL�ߵ�ƽ100��ʱ������,�͵�ƽ100��ʱ������
				  else if( C1 == 150 ) rSCL <= 1'b0;
						  
				  if( C1 == F250K -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end    //����250Khz��IICʱ��
				  else C1 <= C1 + 1'b1; 
			 end
					 
			 16:
			 if( isAck != 0 ) i <= 5'd0;
			 else i <= Go; 
					
  		    endcase
//I2C ���ݶ�	
	  else if( Start_Sig[1] )                     
		    case( i )
				
			 0: // Start
			 begin
			      isOut <= 1;                      //SDA�˿����
					      
			      if( C1 == 0 ) rSCL <= 1'b1;
			 	   else if( C1 == 200 ) rSCL <= 1'b0;      //SCL�ɸ߱��
						  
					if( C1 == 0 ) rSDA <= 1'b1; 
					else if( C1 == 100 ) rSDA <= 1'b0;     //SDA���ɸ߱�� 
						  
					if( C1 == 250 -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end
					 else C1 <= C1 + 1'b1;
			 end
					  
			 1: // Write Device Addr(�豸��ַ)
			 begin rData <= {4'b1010, 3'b000, 1'b0}; i <= 5'd9; Go <= i + 1'b1; end
					 
			 2: // Wirte Word Addr(EEPROM��д��ַ)
			 begin rData <= Addr_Sig; i <= 5'd9; Go <= i + 1'b1; end
					
			 3: // Start again
			 begin
			     isOut <= 1'b1;
					      
			     if( C1 == 0 ) rSCL <= 1'b0;
				  else if( C1 == 50 ) rSCL <= 1'b1; 
				  else if( C1 == 250 ) rSCL <= 1'b0;
						  
			     if( C1 == 0 ) rSDA <= 1'b0; 
				  else if( C1 == 50 ) rSDA <= 1'b1;
				  else if( C1 == 150 ) rSDA <= 1'b0;  
						  
				  if( C1 == 300 -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end
				  else C1 <= C1 + 1'b1;
			 end
					 
			 4: // Write Device Addr ( Read )
			 begin rData <= {4'b1010, 3'b000, 1'b1}; i <= 5'd9; Go <= i + 1'b1; end
					
			 5: // Read Data
			 begin rData <= 8'd0; i <= 5'd19; Go <= i + 1'b1; end
				 
			 6: // Stop
			 begin
			     isOut <= 1'b1;
			     if( C1 == 0 ) rSCL <= 1'b0;
				  else if( C1 == 50 ) rSCL <= 1'b1; 
		
				  if( C1 == 0 ) rSDA <= 1'b0;
				  else if( C1 == 150 ) rSDA <= 1'b1;
					 	  
				  if( C1 == 250 -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end
				  else C1 <= C1 + 1'b1; 
			 end
					 
			 7:                                                       //дI2C ����
			 begin isDone <= 1'b1; i <= i + 1'b1; end
					 
			 8: 
			 begin isDone <= 1'b0; i <= 5'd0; end
				 
					
			 9,10,11,12,13,14,15,16:                                  //����Device Addr(write)/Word Addr/Device Addr(read)
			 begin
			      isOut <= 1'b1;					      
			 	   rSDA <= rData[16-i];                                //��λ�ȷ���
						  
				   if( C1 == 0 ) rSCL <= 1'b0;
					else if( C1 == 50 ) rSCL <= 1'b1;                   //SCL�ߵ�ƽ100��ʱ������,�͵�ƽ100��ʱ������
					else if( C1 == 150 ) rSCL <= 1'b0; 
						  
					if( C1 == F250K -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end   //����250Khz��IICʱ��
					else C1 <= C1 + 1'b1;
			 end
			       
			 17: // waiting for acknowledge
			 begin
			      isOut <= 1'b0;                                       //SDA�˿ڸ�Ϊ����
					     
			 	   if( C1 == 100 ) isAck <= SDA;                        //��ȡIIC ��Ӧ���ź�
						  
					if( C1 == 0 ) rSCL <= 1'b0;
					else if( C1 == 50 ) rSCL <= 1'b1;                 //SCL�ߵ�ƽ100��ʱ������,�͵�ƽ100��ʱ������
					else if( C1 == 150 ) rSCL <= 1'b0;
						  
					if( C1 == F250K -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end     //����250Khz��IICʱ��
					else C1 <= C1 + 1'b1; 
			 end
					 
			 18:
			      if( isAck != 0 ) i <= 5'd0;
					else i <= Go;
					 
					 
			 19,20,21,22,23,24,25,26: // Read data
			 begin
			     isOut <= 1'b0;
			     if( C1 == 100 ) rData[26-i] <= SDA;                              //��λ�Ƚ���
						  
				  if( C1 == 0 ) rSCL <= 1'b0;
				  else if( C1 == 50 ) rSCL <= 1'b1;                  //SCL�ߵ�ƽ100��ʱ������,�͵�ƽ100��ʱ������
				  else if( C1 == 150 ) rSCL <= 1'b0; 
						  
				  if( C1 == F250K -1 ) begin C1 <= 9'd0; i <= i + 1'b1; end     //����250Khz��IICʱ��
				  else C1 <= C1 + 1'b1;
			 end	  
					 
			 27: // no acknowledge
			 begin
			     isOut <= 1'b1;
					  
				  if( C1 == 0 ) rSCL <= 1'b0;
				  else if( C1 == 50 ) rSCL <= 1'b1;
				  else if( C1 == 150 ) rSCL <= 1'b0;
						  
				  if( C1 == F250K -1 ) begin C1 <= 9'd0; i <= Go; end
				  else C1 <= C1 + 1'b1; 
			end
				
			endcase		
		

	
				
endmodule
