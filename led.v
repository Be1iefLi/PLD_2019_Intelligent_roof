`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/01 18:32:49
// Design Name: 
// Module Name: LED_Demo
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
`define LED_Task_msecond_100  2'h0
`define LED_Task_msecond_200  2'h1
`define LED_Task_msecond_500  2'h2
`define LED_Task_second_1     2'h3

`define LED_1   0
`define LED_2   1

//This is a sample demo for LED flashing
module LED_Control(
    output RGB_LED_tri_o,
    output [5:0]RGB,
    input clk_100MHz,
    input [5:0]sw
    );
    wire clk_10MHz;
    wire clk_1kHz;
    wire clk_1MHz;
    
    reg [30:0]Clk_Divide_1kHz=100000/2;
    reg [30:0]Clk_Divide_1MHz=100/2;
    reg [1:0]Task_Num_LED1;
    reg [1:0]Task_Num_LED2;
    reg [7:0]R_In1;
    reg [7:0]G_In1;
    reg [7:0]B_In1;
    reg Rst=1;
    
    //////////////////
    reg [5:0]Period_100mSecond=10;
    reg [10:0]Light_Num=1000;
    /////////////////
    integer Cnt=0;
    wire Light;
    initial
        begin
            Task_Num_LED1=`LED_Task_msecond_500;
            Task_Num_LED2=`LED_Task_msecond_500;
            R_In1=255;
            G_In1=0;
            B_In1=0;
            Rst=1;
        end
    always @(posedge clk_1kHz)
        begin
                if(Cnt==1)
                    begin
                        R_In1<=255;
                        G_In1<=0;
                        B_In1<=0;
                        Rst=0;
                    end
                else if(Cnt==24000)
                    begin
                        R_In1<=0;
                        G_In1<=255;
                        B_In1<=0;
                        Rst=0;
                    end
                else if(Cnt==48000)
                    begin
                        R_In1<=0;
                        G_In1<=0;
                        B_In1<=255;
                        Rst=0;
                    end
                else if(Cnt==72000)
                    begin
                        Cnt=0;
                        Rst=1;
                    end
                else
                    Rst=1;
                
                Cnt=Cnt+1;
        end
    clk_wiz_0 clk_10(.clk_out1(clk_10MHz),.clk_in1(clk_100MHz));
    //时钟分频 
    Clk_Division_0 Clk_Division0(.clk_100MHz(clk_100MHz),.clk_mode(Clk_Divide_1MHz),.clk_out(clk_1MHz));
    Clk_Division_0 Clk_Division1(.clk_100MHz(clk_100MHz),.clk_mode(Clk_Divide_1kHz),.clk_out(clk_1kHz));
    
    
    wire [7:0]R_Out0, R_Out1, R_Out2, R_Out3, R_Out4, R_Out5, R_Out6;
    wire [7:0]G_Out0, G_Out1, G_Out2, G_Out3, G_Out4, G_Out5, G_Out6;
    wire [7:0]B_Out0, B_Out1, B_Out2, B_Out3, B_Out4, B_Out5, B_Out6;
   //RGBLED task instantiation, breathing light
    RGB_LED_Task RGB_LED_Task0(
           .clk_100MHz(clk_100MHz),
           .clk_10MHz(clk_10MHz),
           .Period_100mSecond(Period_100mSecond),
           .R_In(R_In1),
           .G_In(G_In1),
           .B_In(B_In1),
           .R_Out(R_Out0),
           .G_Out(G_Out0),
           .B_Out(B_Out0),
           .Light_Num(Light_Num),
           .Rst(Rst),
           .Light_Ok(Light)
           );
           
    assign R_Out1 = sw[0]? R_Out0:0;
    assign G_Out1 = sw[0]? G_Out0:0;
    assign B_Out1 = sw[0]? B_Out0:0;
    assign R_Out2 = sw[1]? R_Out0:0;
    assign G_Out2 = sw[1]? G_Out0:0;
    assign B_Out2 = sw[1]? B_Out0:0;
    assign R_Out3 = sw[2]? R_Out0:0;
    assign G_Out3 = sw[2]? G_Out0:0;
    assign B_Out3 = sw[2]? B_Out0:0;
    assign R_Out4 = sw[3]? R_Out0:0;
    assign G_Out4 = sw[3]? G_Out0:0;
    assign B_Out4 = sw[3]? B_Out0:0;
    assign R_Out5 = sw[4]? R_Out0:0;
    assign G_Out5 = sw[4]? G_Out0:0;
    assign B_Out5 = sw[4]? B_Out0:0;
    assign R_Out6 = sw[5]? R_Out0:0;
    assign G_Out6 = sw[5]? G_Out0:0;
    assign B_Out6 = sw[5]? B_Out0:0;
    //实例化SK6805驱动
    Driver_SK6805 Driver_SK6805_0(.R_In1(R_Out0),.G_In1(G_Out0),.B_In1(B_Out0),.R_In2(R_Out0),.G_In2(G_Out0),.B_In2(B_Out0),.clk_10MHz(clk_10MHz),.Rst(Rst),.LED_IO(RGB_LED_tri_o));
    Driver_SK6805 Driver_SK6805_1(.R_In1(R_Out1),.G_In1(G_Out1),.B_In1(B_Out1),.R_In2(R_Out1),.G_In2(G_Out1),.B_In2(B_Out1),.clk_10MHz(clk_10MHz),.Rst(Rst),.LED_IO(RGB[0]));
    Driver_SK6805 Driver_SK6805_2(.R_In1(R_Out2),.G_In1(G_Out2),.B_In1(B_Out2),.R_In2(R_Out2),.G_In2(G_Out2),.B_In2(B_Out2),.clk_10MHz(clk_10MHz),.Rst(Rst),.LED_IO(RGB[1]));
    Driver_SK6805 Driver_SK6805_3(.R_In1(R_Out3),.G_In1(G_Out3),.B_In1(B_Out3),.R_In2(R_Out3),.G_In2(G_Out3),.B_In2(B_Out3),.clk_10MHz(clk_10MHz),.Rst(Rst),.LED_IO(RGB[2]));
    Driver_SK6805 Driver_SK6805_4(.R_In1(R_Out4),.G_In1(G_Out4),.B_In1(B_Out4),.R_In2(R_Out4),.G_In2(G_Out4),.B_In2(B_Out4),.clk_10MHz(clk_10MHz),.Rst(Rst),.LED_IO(RGB[3]));
    Driver_SK6805 Driver_SK6805_5(.R_In1(R_Out5),.G_In1(G_Out5),.B_In1(B_Out5),.R_In2(R_Out5),.G_In2(G_Out5),.B_In2(B_Out5),.clk_10MHz(clk_10MHz),.Rst(Rst),.LED_IO(RGB[4]));
    Driver_SK6805 Driver_SK6805_6(.R_In1(R_Out6),.G_In1(G_Out6),.B_In1(B_Out6),.R_In2(R_Out6),.G_In2(G_Out6),.B_In2(B_Out6),.clk_10MHz(clk_10MHz),.Rst(Rst),.LED_IO(RGB[5]));
endmodule