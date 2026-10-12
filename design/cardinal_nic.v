module cardinal_nic(
    input clk,          
    input reset,    
    //to processor
    input [1:0] addr,   
    input [63:0] d_in,  
    input nicEn,        
    input nicWrEn,      
    output reg [63:0] d_out, 
    //to net
    output net_so,       
    input net_ro,       
    output [63:0] net_do,
    input net_polarity, 
    input net_si,       
    output net_ri,       
    input [63:0] net_di 
);
    // Local re-timed reset: the chip-level reset only drives this flop,
    // the block-wide reset fan-out becomes a short reg->reg path.
    reg rst;
    always @(posedge clk) rst <= reset;

    reg [63:0] input_buffer;   
    reg input_status;
    reg [63:0] output_buffer;  
    reg output_status;

    // input_buffer
    // FIX: only accept new packet when input buffer is empty (!input_status)
    // Previously: if(net_si) input_buffer <= net_di
    // This caused race condition where a fast packet from a nearby node
    // could overwrite a just-arrived packet before the CPU had a chance to read it.
    always@(posedge clk) begin
        if(rst)
            input_buffer <= 0;
        else if(net_si && !input_status)  // <-- FIXED: guard with !input_status
            input_buffer <= net_di;
    end

    // input_status
    always@(posedge clk) begin
        if(rst)
            input_status <= 0;
        else if(net_si && !input_status)  // <-- FIXED: consistent with input_buffer guard
            input_status <= 1;
        else if(nicEn && !nicWrEn && (addr == 2'b00))
            input_status <= 0;
    end

    // output_buffer
    always@(posedge clk) begin
        if(rst)
            output_buffer <= 0;
        else if(nicEn && nicWrEn && (addr == 2'b10) && (output_status == 0))
            output_buffer <= d_in;
    end

    // output_status
    always@(posedge clk) begin
        if(rst)
            output_status <= 0;
        else if(nicEn && nicWrEn && (addr == 2'b10) && (output_status == 0))
            output_status <= 1;
        else if(net_so && net_ro)
            output_status <= 0;
    end

    assign net_so = output_status && net_ro && (net_polarity == 1'b0);
    assign net_do = output_buffer;	
    assign net_ri = ~input_status;

    always @(posedge clk) begin
        if (rst) begin
            d_out <= 64'd0;
        end else if (nicEn && !nicWrEn) begin
            case (addr)
                2'b00: d_out <= input_buffer;
                2'b01: d_out <= {63'd0, input_status};
                2'b11: d_out <= {63'd0, output_status};
                default: d_out <= 64'd0;
            endcase
        end else begin
            d_out <= 64'd0;
        end
    end

endmodule