module cardinal_router(
	input clk,
	input reset,
	output reg polarity,
	input esi,
	output eri,
	input [63:0] edi,
	output eso,
	input ero,
	output [63:0] edo,
	output peso,
	input pero,
	output [63:0] pedo,
	
	input ssi,
	output sri,
	input [63:0] sdi,
	output sso,
	input sro,
	output [63:0] sdo,
	
	input wsi,
	output wri,
	input [63:0] wdi,
	output wso,
	input wro,
	output [63:0] wdo,
	input pesi,
	output peri,
	input [63:0] pedi,
	
	input nsi,
	output nri,
	input [63:0] ndi,
	output nso,
	input nro,
	output [63:0] ndo

);

// Local re-timed reset: the chip-level reset only drives this flop,
// the block-wide reset fan-out becomes a short reg->reg path.
reg rst;
always @(posedge clk) rst <= reset;

// polarity (0=even, 1=odd)
always@(posedge clk)begin
	if(rst) polarity <= 0;
	else polarity <= ~polarity;
end

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++ Left-Hand Side ++++++++++++++++++++++++++++++++++++++++++++++++++++++++


// ================================================================================
//                                       North
// ================================================================================
reg [63:0] north_odd_reg, north_even_reg;
reg north_odd_full, north_even_full;
wire north_odd_granted, north_even_granted;

always@(posedge clk)begin
    if(rst)begin
        north_odd_full <= 0;
        north_odd_reg  <= 0; 
    end
    else begin
        if(polarity == 0 && nsi && !north_odd_full)begin
            north_odd_reg  <= ndi;
            north_odd_full <= 1; 
        end
        else if(north_odd_granted)begin
            north_odd_full <= 0; 
        end
    end
end

wire [3:0] n_odd_hopX = north_odd_reg[55:52];
wire [3:0] n_odd_hopY = north_odd_reg[51:48];
wire n_odd_dirX = north_odd_reg[62];
wire n_odd_dirY = north_odd_reg[61];

// FIX: use != 0 instead of [0]==1 for routing decision
wire n_odd_req_E  = north_odd_full & (n_odd_hopX != 4'b0) & (n_odd_dirX == 0);
wire n_odd_req_W  = north_odd_full & (n_odd_hopX != 4'b0) & (n_odd_dirX == 1);
wire n_odd_req_S  = north_odd_full & (n_odd_hopX == 4'b0) & (n_odd_hopY != 4'b0) & (n_odd_dirY == 0);
wire n_odd_req_N  = north_odd_full & (n_odd_hopX == 4'b0) & (n_odd_hopY != 4'b0) & (n_odd_dirY == 1);
wire n_odd_req_PE = north_odd_full & (n_odd_hopX == 4'b0) & (n_odd_hopY == 4'b0);

always@(posedge clk)begin
    if(rst)begin
        north_even_full <= 0;
        north_even_reg  <= 0;
    end
    else begin
        if(polarity == 1 && nsi && !north_even_full)begin
            north_even_reg  <= ndi;
            north_even_full <= 1; 
        end
        else if(north_even_granted)begin
            north_even_full <= 0; 
        end
    end
end

wire [3:0] n_even_hopX = north_even_reg[55:52];
wire [3:0] n_even_hopY = north_even_reg[51:48];
wire n_even_dirX = north_even_reg[62];
wire n_even_dirY = north_even_reg[61];

wire n_even_req_E  = north_even_full & (n_even_hopX != 4'b0) & (n_even_dirX == 0);
wire n_even_req_W  = north_even_full & (n_even_hopX != 4'b0) & (n_even_dirX == 1);
wire n_even_req_S  = north_even_full & (n_even_hopX == 4'b0) & (n_even_hopY != 4'b0) & (n_even_dirY == 0);
wire n_even_req_N  = north_even_full & (n_even_hopX == 4'b0) & (n_even_hopY != 4'b0) & (n_even_dirY == 1);
wire n_even_req_PE = north_even_full & (n_even_hopX == 4'b0) & (n_even_hopY == 4'b0);

assign nri = (polarity == 0) ? (!north_odd_full) : (!north_even_full);

// ================================================================================
//                                       South
// ================================================================================
reg [63:0] south_odd_reg, south_even_reg;
reg south_odd_full, south_even_full;
wire south_odd_granted, south_even_granted;

always@(posedge clk)begin
    if(rst)begin
        south_odd_full <= 0;
        south_odd_reg  <= 0; 
    end
    else begin
        if(polarity == 0 && ssi && !south_odd_full)begin
            south_odd_reg  <= sdi;
            south_odd_full <= 1; 
        end
        else if(south_odd_granted)begin
            south_odd_full <= 0; 
        end
    end
end

wire [3:0] s_odd_hopX = south_odd_reg[55:52];
wire [3:0] s_odd_hopY = south_odd_reg[51:48];
wire s_odd_dirX = south_odd_reg[62];
wire s_odd_dirY = south_odd_reg[61];

wire s_odd_req_E  = south_odd_full & (s_odd_hopX != 4'b0) & (s_odd_dirX == 0);
wire s_odd_req_W  = south_odd_full & (s_odd_hopX != 4'b0) & (s_odd_dirX == 1);
wire s_odd_req_S  = south_odd_full & (s_odd_hopX == 4'b0) & (s_odd_hopY != 4'b0) & (s_odd_dirY == 0);
wire s_odd_req_N  = south_odd_full & (s_odd_hopX == 4'b0) & (s_odd_hopY != 4'b0) & (s_odd_dirY == 1);
wire s_odd_req_PE = south_odd_full & (s_odd_hopX == 4'b0) & (s_odd_hopY == 4'b0);

always@(posedge clk)begin
    if(rst)begin
        south_even_full <= 0;
        south_even_reg  <= 0;
    end
    else begin
        if(polarity == 1 && ssi && !south_even_full)begin
            south_even_reg  <= sdi;
            south_even_full <= 1; 
        end
        else if(south_even_granted)begin
            south_even_full <= 0; 
        end
    end
end

wire [3:0] s_even_hopX = south_even_reg[55:52];
wire [3:0] s_even_hopY = south_even_reg[51:48];
wire s_even_dirX = south_even_reg[62];
wire s_even_dirY = south_even_reg[61];

wire s_even_req_E  = south_even_full & (s_even_hopX != 4'b0) & (s_even_dirX == 0);
wire s_even_req_W  = south_even_full & (s_even_hopX != 4'b0) & (s_even_dirX == 1);
wire s_even_req_S  = south_even_full & (s_even_hopX == 4'b0) & (s_even_hopY != 4'b0) & (s_even_dirY == 0);
wire s_even_req_N  = south_even_full & (s_even_hopX == 4'b0) & (s_even_hopY != 4'b0) & (s_even_dirY == 1);
wire s_even_req_PE = south_even_full & (s_even_hopX == 4'b0) & (s_even_hopY == 4'b0);

assign sri = (polarity == 0) ? (!south_odd_full) : (!south_even_full);

// ================================================================================
//                                       East
// ================================================================================
reg [63:0] east_odd_reg, east_even_reg;
reg east_odd_full, east_even_full;
wire east_odd_granted, east_even_granted;

always@(posedge clk)begin
    if(rst)begin
        east_odd_full <= 0;
        east_odd_reg  <= 0; 
    end
    else begin
        if(polarity == 0 && esi && !east_odd_full)begin
            east_odd_reg  <= edi;
            east_odd_full <= 1; 
        end
        else if(east_odd_granted)begin
            east_odd_full <= 0; 
        end
    end
end

wire [3:0] e_odd_hopX = east_odd_reg[55:52];
wire [3:0] e_odd_hopY = east_odd_reg[51:48];
wire e_odd_dirX = east_odd_reg[62];
wire e_odd_dirY = east_odd_reg[61];

wire e_odd_req_E  = east_odd_full & (e_odd_hopX != 4'b0) & (e_odd_dirX == 0);
wire e_odd_req_W  = east_odd_full & (e_odd_hopX != 4'b0) & (e_odd_dirX == 1);
wire e_odd_req_S  = east_odd_full & (e_odd_hopX == 4'b0) & (e_odd_hopY != 4'b0) & (e_odd_dirY == 0);
wire e_odd_req_N  = east_odd_full & (e_odd_hopX == 4'b0) & (e_odd_hopY != 4'b0) & (e_odd_dirY == 1);
wire e_odd_req_PE = east_odd_full & (e_odd_hopX == 4'b0) & (e_odd_hopY == 4'b0);

always@(posedge clk)begin
    if(rst)begin
        east_even_full <= 0;
        east_even_reg  <= 0;
    end
    else begin
        if(polarity == 1 && esi && !east_even_full)begin
            east_even_reg  <= edi;
            east_even_full <= 1; 
        end
        else if(east_even_granted)begin
            east_even_full <= 0; 
        end
    end
end

wire [3:0] e_even_hopX = east_even_reg[55:52];
wire [3:0] e_even_hopY = east_even_reg[51:48];
wire e_even_dirX = east_even_reg[62];
wire e_even_dirY = east_even_reg[61];

wire e_even_req_E  = east_even_full & (e_even_hopX != 4'b0) & (e_even_dirX == 0);
wire e_even_req_W  = east_even_full & (e_even_hopX != 4'b0) & (e_even_dirX == 1);
wire e_even_req_S  = east_even_full & (e_even_hopX == 4'b0) & (e_even_hopY != 4'b0) & (e_even_dirY == 0);
wire e_even_req_N  = east_even_full & (e_even_hopX == 4'b0) & (e_even_hopY != 4'b0) & (e_even_dirY == 1);
wire e_even_req_PE = east_even_full & (e_even_hopX == 4'b0) & (e_even_hopY == 4'b0);

assign eri = (polarity == 0) ? (!east_odd_full) : (!east_even_full);

// ================================================================================
//                                       West
// ================================================================================
reg [63:0] west_odd_reg, west_even_reg;
reg west_odd_full, west_even_full;
wire west_odd_granted, west_even_granted;

always@(posedge clk)begin
    if(rst)begin
        west_odd_full <= 0;
        west_odd_reg  <= 0; 
    end
    else begin
        if(polarity == 0 && wsi && !west_odd_full)begin
            west_odd_reg  <= wdi;
            west_odd_full <= 1; 
        end
        else if(west_odd_granted)begin
            west_odd_full <= 0; 
        end
    end
end

wire [3:0] w_odd_hopX = west_odd_reg[55:52];
wire [3:0] w_odd_hopY = west_odd_reg[51:48];
wire w_odd_dirX = west_odd_reg[62];
wire w_odd_dirY = west_odd_reg[61];

wire w_odd_req_E  = west_odd_full & (w_odd_hopX != 4'b0) & (w_odd_dirX == 0);
wire w_odd_req_W  = west_odd_full & (w_odd_hopX != 4'b0) & (w_odd_dirX == 1);
wire w_odd_req_S  = west_odd_full & (w_odd_hopX == 4'b0) & (w_odd_hopY != 4'b0) & (w_odd_dirY == 0);
wire w_odd_req_N  = west_odd_full & (w_odd_hopX == 4'b0) & (w_odd_hopY != 4'b0) & (w_odd_dirY == 1);
wire w_odd_req_PE = west_odd_full & (w_odd_hopX == 4'b0) & (w_odd_hopY == 4'b0);

always@(posedge clk)begin
    if(rst)begin
        west_even_full <= 0;
        west_even_reg  <= 0;
    end
    else begin
        if(polarity == 1 && wsi && !west_even_full)begin
            west_even_reg  <= wdi;
            west_even_full <= 1; 
        end
        else if(west_even_granted)begin
            west_even_full <= 0; 
        end
    end
end

wire [3:0] w_even_hopX = west_even_reg[55:52];
wire [3:0] w_even_hopY = west_even_reg[51:48];
wire w_even_dirX = west_even_reg[62];
wire w_even_dirY = west_even_reg[61];

wire w_even_req_E  = west_even_full & (w_even_hopX != 4'b0) & (w_even_dirX == 0);
wire w_even_req_W  = west_even_full & (w_even_hopX != 4'b0) & (w_even_dirX == 1);
wire w_even_req_S  = west_even_full & (w_even_hopX == 4'b0) & (w_even_hopY != 4'b0) & (w_even_dirY == 0);
wire w_even_req_N  = west_even_full & (w_even_hopX == 4'b0) & (w_even_hopY != 4'b0) & (w_even_dirY == 1);
wire w_even_req_PE = west_even_full & (w_even_hopX == 4'b0) & (w_even_hopY == 4'b0);

assign wri = (polarity == 0) ? (!west_odd_full) : (!west_even_full);

// ================================================================================
//                                       PE
// ================================================================================
reg [63:0] pe_odd_reg, pe_even_reg;
reg pe_odd_full, pe_even_full;
wire pe_odd_granted, pe_even_granted;

always@(posedge clk)begin
    if(rst)begin
        pe_odd_full <= 0;
        pe_odd_reg  <= 0; 
    end
    else begin
        if(polarity == 0 && pesi && !pe_odd_full)begin
            pe_odd_reg  <= pedi;
            pe_odd_full <= 1; 
        end
        else if(pe_odd_granted)begin
            pe_odd_full <= 0; 
        end
    end
end

wire [3:0] pe_odd_hopX = pe_odd_reg[55:52];
wire [3:0] pe_odd_hopY = pe_odd_reg[51:48];
wire pe_odd_dirX = pe_odd_reg[62];
wire pe_odd_dirY = pe_odd_reg[61];

wire pe_odd_req_E  = pe_odd_full & (pe_odd_hopX != 4'b0) & (pe_odd_dirX == 0);
wire pe_odd_req_W  = pe_odd_full & (pe_odd_hopX != 4'b0) & (pe_odd_dirX == 1);
wire pe_odd_req_S  = pe_odd_full & (pe_odd_hopX == 4'b0) & (pe_odd_hopY != 4'b0) & (pe_odd_dirY == 0);
wire pe_odd_req_N  = pe_odd_full & (pe_odd_hopX == 4'b0) & (pe_odd_hopY != 4'b0) & (pe_odd_dirY == 1);
wire pe_odd_req_PE = pe_odd_full & (pe_odd_hopX == 4'b0) & (pe_odd_hopY == 4'b0);

always@(posedge clk)begin
    if(rst)begin
        pe_even_full <= 0;
        pe_even_reg  <= 0;
    end
    else begin
        if(polarity == 1 && pesi && !pe_even_full)begin
            pe_even_reg  <= pedi;
            pe_even_full <= 1; 
        end
        else if(pe_even_granted)begin
            pe_even_full <= 0; 
        end
    end
end

wire [3:0] pe_even_hopX = pe_even_reg[55:52];
wire [3:0] pe_even_hopY = pe_even_reg[51:48];
wire pe_even_dirX = pe_even_reg[62];
wire pe_even_dirY = pe_even_reg[61];

wire pe_even_req_E  = pe_even_full & (pe_even_hopX != 4'b0) & (pe_even_dirX == 0);
wire pe_even_req_W  = pe_even_full & (pe_even_hopX != 4'b0) & (pe_even_dirX == 1);
wire pe_even_req_S  = pe_even_full & (pe_even_hopX == 4'b0) & (pe_even_hopY != 4'b0) & (pe_even_dirY == 0);
wire pe_even_req_N  = pe_even_full & (pe_even_hopX == 4'b0) & (pe_even_hopY != 4'b0) & (pe_even_dirY == 1);
wire pe_even_req_PE = pe_even_full & (pe_even_hopX == 4'b0) & (pe_even_hopY == 4'b0);

assign peri = (polarity == 0) ? (!pe_odd_full) : (!pe_even_full);


// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++ Right-Hand Side ++++++++++++++++++++++++++++++++++++++++++++++++++++++++


// ================================================================================
//                                       North output
// ================================================================================

reg [63:0] n_out_odd_reg, n_out_even_reg;
reg n_out_odd_full, n_out_even_full;
reg [1:0] n_odd_priority, n_even_priority;

// ---------------------------------- Odd ----------------------------------
wire req_S_to_N_odd  = s_odd_req_N;
wire req_E_to_N_odd  = e_odd_req_N;
wire req_W_to_N_odd  = w_odd_req_N;
wire req_PE_to_N_odd = pe_odd_req_N;

reg grant_S_to_N_odd, grant_E_to_N_odd, grant_W_to_N_odd, grant_PE_to_N_odd;

always@(posedge clk)begin
	if(rst)begin
		n_out_odd_reg <= 0;
		n_out_odd_full <= 0;
		n_odd_priority <= 0;
	end
	else begin
		if(grant_S_to_N_odd)begin
            // FIX: subtract 1 from hopY field [51:48]
            n_out_odd_reg <= {south_odd_reg[63:52], south_odd_reg[51:48]-4'd1, south_odd_reg[47:0]};
            n_out_odd_full <= 1;
            n_odd_priority <= 2'd1; 
        end
        else if(grant_E_to_N_odd)begin
            n_out_odd_reg <= {east_odd_reg[63:52], east_odd_reg[51:48]-4'd1, east_odd_reg[47:0]};
            n_out_odd_full <= 1;
            n_odd_priority <= 2'd2; 
        end
        else if(grant_W_to_N_odd)begin
            n_out_odd_reg <= {west_odd_reg[63:52], west_odd_reg[51:48]-4'd1, west_odd_reg[47:0]};
            n_out_odd_full <= 1;
            n_odd_priority <= 2'd3; 
        end
        else if(grant_PE_to_N_odd)begin
            n_out_odd_reg <= {pe_odd_reg[63:52], pe_odd_reg[51:48]-4'd1, pe_odd_reg[47:0]};
            n_out_odd_full <= 1;
            n_odd_priority <= 2'd0; 
        end
        else if(polarity == 1'b0 && n_out_odd_full && nro)begin
            n_out_odd_full <= 0;
        end
	end
end

always@(*)begin
	grant_S_to_N_odd = 0;
	grant_E_to_N_odd = 0;
	grant_W_to_N_odd = 0;
	grant_PE_to_N_odd = 0;
	
	if(!n_out_odd_full && polarity == 1'b1)begin
        case (n_odd_priority)
            2'd0: begin 
                if(req_S_to_N_odd) grant_S_to_N_odd  = 1;
                else if(req_E_to_N_odd) grant_E_to_N_odd  = 1;
                else if(req_W_to_N_odd) grant_W_to_N_odd  = 1;
                else if(req_PE_to_N_odd) grant_PE_to_N_odd = 1;
            end
            2'd1: begin
                if(req_E_to_N_odd) grant_E_to_N_odd  = 1;
                else if(req_W_to_N_odd) grant_W_to_N_odd  = 1;
                else if(req_PE_to_N_odd) grant_PE_to_N_odd = 1;
                else if(req_S_to_N_odd) grant_S_to_N_odd  = 1;
            end
            2'd2: begin
                if(req_W_to_N_odd) grant_W_to_N_odd  = 1;
                else if(req_PE_to_N_odd) grant_PE_to_N_odd = 1;
                else if(req_S_to_N_odd) grant_S_to_N_odd  = 1;
                else if(req_E_to_N_odd) grant_E_to_N_odd  = 1;
            end
            2'd3: begin
                if(req_PE_to_N_odd) grant_PE_to_N_odd = 1;
                else if(req_S_to_N_odd) grant_S_to_N_odd  = 1;
                else if(req_E_to_N_odd) grant_E_to_N_odd  = 1;
                else if(req_W_to_N_odd) grant_W_to_N_odd  = 1;
            end
        endcase
    end
end

// ---------------------------------- Even ----------------------------------
wire req_S_to_N_even  = s_even_req_N;
wire req_E_to_N_even  = e_even_req_N;
wire req_W_to_N_even  = w_even_req_N;
wire req_PE_to_N_even = pe_even_req_N;

reg grant_S_to_N_even, grant_E_to_N_even, grant_W_to_N_even, grant_PE_to_N_even;

always@(posedge clk)begin
	if(rst)begin
		n_out_even_reg <= 0;
		n_out_even_full <= 0;
		n_even_priority <= 0;
	end
	else begin
		if(grant_S_to_N_even)begin
            n_out_even_reg <= {south_even_reg[63:52], south_even_reg[51:48]-4'd1, south_even_reg[47:0]};
            n_out_even_full <= 1;
            n_even_priority <= 2'd1; 
        end
        else if(grant_E_to_N_even)begin
            n_out_even_reg <= {east_even_reg[63:52], east_even_reg[51:48]-4'd1, east_even_reg[47:0]};
            n_out_even_full <= 1;
            n_even_priority <= 2'd2; 
        end
        else if(grant_W_to_N_even)begin
            n_out_even_reg <= {west_even_reg[63:52], west_even_reg[51:48]-4'd1, west_even_reg[47:0]};
            n_out_even_full <= 1;
            n_even_priority <= 2'd3; 
        end
        else if(grant_PE_to_N_even)begin
            n_out_even_reg <= {pe_even_reg[63:52], pe_even_reg[51:48]-4'd1, pe_even_reg[47:0]};
            n_out_even_full <= 1;
            n_even_priority <= 2'd0; 
        end
        else if(polarity == 1'b1 && n_out_even_full && nro)begin
            n_out_even_full <= 0;
        end
	end
end

always@(*)begin
	grant_S_to_N_even = 0;
	grant_E_to_N_even = 0;
	grant_W_to_N_even = 0;
	grant_PE_to_N_even = 0;
	
	if(!n_out_even_full && polarity == 1'b0)begin
        case (n_even_priority)
            2'd0: begin 
                if(req_S_to_N_even) grant_S_to_N_even  = 1;
                else if(req_E_to_N_even) grant_E_to_N_even  = 1;
                else if(req_W_to_N_even) grant_W_to_N_even  = 1;
                else if(req_PE_to_N_even) grant_PE_to_N_even = 1;
            end
            2'd1: begin
                if(req_E_to_N_even) grant_E_to_N_even  = 1;
                else if(req_W_to_N_even) grant_W_to_N_even  = 1;
                else if(req_PE_to_N_even) grant_PE_to_N_even = 1;
                else if(req_S_to_N_even) grant_S_to_N_even  = 1;
            end
            2'd2: begin
                if(req_W_to_N_even) grant_W_to_N_even  = 1;
                else if(req_PE_to_N_even) grant_PE_to_N_even = 1;
                else if(req_S_to_N_even) grant_S_to_N_even  = 1;
                else if(req_E_to_N_even) grant_E_to_N_even  = 1;
            end
            2'd3: begin
                if(req_PE_to_N_even) grant_PE_to_N_even = 1;
                else if(req_S_to_N_even) grant_S_to_N_even  = 1;
                else if(req_E_to_N_even) grant_E_to_N_even  = 1;
                else if(req_W_to_N_even) grant_W_to_N_even  = 1;
            end
        endcase
    end
end


// ================================================================================
//                                       South output
// ================================================================================

reg [63:0] s_out_odd_reg, s_out_even_reg;
reg s_out_odd_full, s_out_even_full;
reg [1:0] s_odd_priority, s_even_priority;

// ---------------------------------- Odd ----------------------------------
wire req_N_to_S_odd  = n_odd_req_S;
wire req_E_to_S_odd  = e_odd_req_S;
wire req_W_to_S_odd  = w_odd_req_S;
wire req_PE_to_S_odd = pe_odd_req_S;

reg grant_N_to_S_odd, grant_E_to_S_odd, grant_W_to_S_odd, grant_PE_to_S_odd;

always@(posedge clk)begin
	if(rst)begin
		s_out_odd_reg <= 0;
		s_out_odd_full <= 0;
		s_odd_priority <= 0;
	end
	else begin
		if(grant_N_to_S_odd)begin
            s_out_odd_reg <= {north_odd_reg[63:52], north_odd_reg[51:48]-4'd1, north_odd_reg[47:0]};
            s_out_odd_full <= 1;
            s_odd_priority <= 2'd1; 
        end
        else if(grant_E_to_S_odd)begin
            s_out_odd_reg <= {east_odd_reg[63:52], east_odd_reg[51:48]-4'd1, east_odd_reg[47:0]};
            s_out_odd_full <= 1;
            s_odd_priority <= 2'd2; 
        end
        else if(grant_W_to_S_odd)begin
            s_out_odd_reg <= {west_odd_reg[63:52], west_odd_reg[51:48]-4'd1, west_odd_reg[47:0]};
            s_out_odd_full <= 1;
            s_odd_priority <= 2'd3; 
        end
        else if(grant_PE_to_S_odd)begin
            s_out_odd_reg <= {pe_odd_reg[63:52], pe_odd_reg[51:48]-4'd1, pe_odd_reg[47:0]};
            s_out_odd_full <= 1;
            s_odd_priority <= 2'd0; 
        end
        else if(polarity == 1'b0 && s_out_odd_full && sro)begin
            s_out_odd_full <= 0;
        end
	end
end

always@(*)begin
	grant_N_to_S_odd = 0;
	grant_E_to_S_odd = 0;
	grant_W_to_S_odd = 0;
	grant_PE_to_S_odd = 0;
	
	if(!s_out_odd_full && polarity == 1'b1)begin
        case (s_odd_priority)
            2'd0: begin 
                if(req_N_to_S_odd) grant_N_to_S_odd  = 1;
                else if(req_E_to_S_odd) grant_E_to_S_odd  = 1;
                else if(req_W_to_S_odd) grant_W_to_S_odd  = 1;
                else if(req_PE_to_S_odd) grant_PE_to_S_odd = 1;
            end
            2'd1: begin
                if(req_E_to_S_odd) grant_E_to_S_odd  = 1;
                else if(req_W_to_S_odd) grant_W_to_S_odd  = 1;
                else if(req_PE_to_S_odd) grant_PE_to_S_odd = 1;
                else if(req_N_to_S_odd) grant_N_to_S_odd  = 1;
            end
            2'd2: begin
                if(req_W_to_S_odd) grant_W_to_S_odd  = 1;
                else if(req_PE_to_S_odd) grant_PE_to_S_odd = 1;
                else if(req_N_to_S_odd) grant_N_to_S_odd  = 1;
                else if(req_E_to_S_odd) grant_E_to_S_odd  = 1;
            end
            2'd3: begin
                if(req_PE_to_S_odd) grant_PE_to_S_odd = 1;
                else if(req_N_to_S_odd) grant_N_to_S_odd  = 1;
                else if(req_E_to_S_odd) grant_E_to_S_odd  = 1;
                else if(req_W_to_S_odd) grant_W_to_S_odd  = 1;
            end
        endcase
    end
end

// ---------------------------------- Even ----------------------------------
wire req_N_to_S_even  = n_even_req_S;
wire req_E_to_S_even  = e_even_req_S;
wire req_W_to_S_even  = w_even_req_S;
wire req_PE_to_S_even = pe_even_req_S;

reg grant_N_to_S_even, grant_E_to_S_even, grant_W_to_S_even, grant_PE_to_S_even;

always@(posedge clk)begin
	if(rst)begin
		s_out_even_reg <= 0;
		s_out_even_full <= 0;
		s_even_priority <= 0;
	end
	else begin
		if(grant_N_to_S_even)begin
            s_out_even_reg <= {north_even_reg[63:52], north_even_reg[51:48]-4'd1, north_even_reg[47:0]};
            s_out_even_full <= 1;
            s_even_priority <= 2'd1; 
        end
        else if(grant_E_to_S_even)begin
            s_out_even_reg <= {east_even_reg[63:52], east_even_reg[51:48]-4'd1, east_even_reg[47:0]};
            s_out_even_full <= 1;
            s_even_priority <= 2'd2; 
        end
        else if(grant_W_to_S_even)begin
            s_out_even_reg <= {west_even_reg[63:52], west_even_reg[51:48]-4'd1, west_even_reg[47:0]};
            s_out_even_full <= 1;
            s_even_priority <= 2'd3; 
        end
        else if(grant_PE_to_S_even)begin
            s_out_even_reg <= {pe_even_reg[63:52], pe_even_reg[51:48]-4'd1, pe_even_reg[47:0]};
            s_out_even_full <= 1;
            s_even_priority <= 2'd0; 
        end
        else if(polarity == 1'b1 && s_out_even_full && sro)begin
            s_out_even_full <= 0;
        end
	end
end

always@(*)begin
	grant_N_to_S_even = 0;
	grant_E_to_S_even = 0;
	grant_W_to_S_even = 0;
	grant_PE_to_S_even = 0;
	
	if(!s_out_even_full && polarity == 1'b0)begin
        case (s_even_priority)
            2'd0: begin 
                if(req_N_to_S_even) grant_N_to_S_even  = 1;
                else if(req_E_to_S_even) grant_E_to_S_even  = 1;
                else if(req_W_to_S_even) grant_W_to_S_even  = 1;
                else if(req_PE_to_S_even) grant_PE_to_S_even = 1;
            end
            2'd1: begin
                if(req_E_to_S_even) grant_E_to_S_even  = 1;
                else if(req_W_to_S_even) grant_W_to_S_even  = 1;
                else if(req_PE_to_S_even) grant_PE_to_S_even = 1;
                else if(req_N_to_S_even) grant_N_to_S_even  = 1;
            end
            2'd2: begin
                if(req_W_to_S_even) grant_W_to_S_even  = 1;
                else if(req_PE_to_S_even) grant_PE_to_S_even = 1;
                else if(req_N_to_S_even) grant_N_to_S_even  = 1;
                else if(req_E_to_S_even) grant_E_to_S_even  = 1;
            end
            2'd3: begin
                if(req_PE_to_S_even) grant_PE_to_S_even = 1;
                else if(req_N_to_S_even) grant_N_to_S_even  = 1;
                else if(req_E_to_S_even) grant_E_to_S_even  = 1;
                else if(req_W_to_S_even) grant_W_to_S_even  = 1;
            end
        endcase
    end
end


// ================================================================================
//                                       East output
// ================================================================================

reg [63:0] e_out_odd_reg, e_out_even_reg;
reg e_out_odd_full, e_out_even_full;
reg [1:0] e_odd_priority, e_even_priority;

// ---------------------------------- Odd ----------------------------------
wire req_N_to_E_odd  = n_odd_req_E;
wire req_S_to_E_odd  = s_odd_req_E;
wire req_W_to_E_odd  = w_odd_req_E;
wire req_PE_to_E_odd = pe_odd_req_E;

reg grant_N_to_E_odd, grant_S_to_E_odd, grant_W_to_E_odd, grant_PE_to_E_odd;

always@(posedge clk)begin
	if(rst)begin
		e_out_odd_reg <= 0;
		e_out_odd_full <= 0;
		e_odd_priority <= 0;
	end
	else begin
		if(grant_N_to_E_odd)begin
            // FIX: subtract 1 from hopX field [55:52]
            e_out_odd_reg <= {north_odd_reg[63:56], north_odd_reg[55:52]-4'd1, north_odd_reg[51:0]};
            e_out_odd_full <= 1;
            e_odd_priority <= 2'd1; 
        end
        else if(grant_S_to_E_odd)begin
            e_out_odd_reg <= {south_odd_reg[63:56], south_odd_reg[55:52]-4'd1, south_odd_reg[51:0]};
            e_out_odd_full <= 1;
            e_odd_priority <= 2'd2; 
        end
        else if(grant_W_to_E_odd)begin
            e_out_odd_reg <= {west_odd_reg[63:56], west_odd_reg[55:52]-4'd1, west_odd_reg[51:0]};
            e_out_odd_full <= 1;
            e_odd_priority <= 2'd3; 
        end
        else if(grant_PE_to_E_odd)begin
            e_out_odd_reg <= {pe_odd_reg[63:56], pe_odd_reg[55:52]-4'd1, pe_odd_reg[51:0]};
            e_out_odd_full <= 1;
            e_odd_priority <= 2'd0; 
        end
        else if(polarity == 1'b0 && e_out_odd_full && ero)begin
            e_out_odd_full <= 0;
        end
	end
end

always@(*)begin
	grant_N_to_E_odd = 0;
	grant_S_to_E_odd = 0;
	grant_W_to_E_odd = 0;
	grant_PE_to_E_odd = 0;
	
	if(!e_out_odd_full && polarity == 1'b1)begin
        case (e_odd_priority)
            2'd0: begin 
                if(req_N_to_E_odd) grant_N_to_E_odd  = 1;
                else if(req_S_to_E_odd) grant_S_to_E_odd  = 1;
                else if(req_W_to_E_odd) grant_W_to_E_odd  = 1;
                else if(req_PE_to_E_odd) grant_PE_to_E_odd = 1;
            end
            2'd1: begin
                if(req_S_to_E_odd) grant_S_to_E_odd  = 1;
                else if(req_W_to_E_odd) grant_W_to_E_odd  = 1;
                else if(req_PE_to_E_odd) grant_PE_to_E_odd = 1;
                else if(req_N_to_E_odd) grant_N_to_E_odd  = 1;
            end
            2'd2: begin
                if(req_W_to_E_odd) grant_W_to_E_odd  = 1;
                else if(req_PE_to_E_odd) grant_PE_to_E_odd = 1;
                else if(req_N_to_E_odd) grant_N_to_E_odd  = 1;
                else if(req_S_to_E_odd) grant_S_to_E_odd  = 1;
            end
            2'd3: begin
                if(req_PE_to_E_odd) grant_PE_to_E_odd = 1;
                else if(req_N_to_E_odd) grant_N_to_E_odd  = 1;
                else if(req_S_to_E_odd) grant_S_to_E_odd  = 1;
                else if(req_W_to_E_odd) grant_W_to_E_odd  = 1;
            end
        endcase
    end
end

// ---------------------------------- Even ----------------------------------
wire req_N_to_E_even  = n_even_req_E;
wire req_S_to_E_even  = s_even_req_E;
wire req_W_to_E_even  = w_even_req_E;
wire req_PE_to_E_even = pe_even_req_E;

reg grant_N_to_E_even, grant_S_to_E_even, grant_W_to_E_even, grant_PE_to_E_even;

always@(posedge clk)begin
	if(rst)begin
		e_out_even_reg <= 0;
		e_out_even_full <= 0;
		e_even_priority <= 0;
	end
	else begin
		if(grant_N_to_E_even)begin
            e_out_even_reg <= {north_even_reg[63:56], north_even_reg[55:52]-4'd1, north_even_reg[51:0]};
            e_out_even_full <= 1;
            e_even_priority <= 2'd1; 
        end
        else if(grant_S_to_E_even)begin
            e_out_even_reg <= {south_even_reg[63:56], south_even_reg[55:52]-4'd1, south_even_reg[51:0]};
            e_out_even_full <= 1;
            e_even_priority <= 2'd2; 
        end
        else if(grant_W_to_E_even)begin
            e_out_even_reg <= {west_even_reg[63:56], west_even_reg[55:52]-4'd1, west_even_reg[51:0]};
            e_out_even_full <= 1;
            e_even_priority <= 2'd3; 
        end
        else if(grant_PE_to_E_even)begin
            e_out_even_reg <= {pe_even_reg[63:56], pe_even_reg[55:52]-4'd1, pe_even_reg[51:0]};
            e_out_even_full <= 1;
            e_even_priority <= 2'd0; 
        end
        else if(polarity == 1'b1 && e_out_even_full && ero)begin
            e_out_even_full <= 0;
        end
	end
end

always@(*)begin
	grant_N_to_E_even = 0;
	grant_S_to_E_even = 0;
	grant_W_to_E_even = 0;
	grant_PE_to_E_even = 0;
	
	if(!e_out_even_full && polarity == 1'b0)begin
        case (e_even_priority)
            2'd0: begin 
                if(req_N_to_E_even) grant_N_to_E_even  = 1;
                else if(req_S_to_E_even) grant_S_to_E_even  = 1;
                else if(req_W_to_E_even) grant_W_to_E_even  = 1;
                else if(req_PE_to_E_even) grant_PE_to_E_even = 1;
            end
            2'd1: begin
                if(req_S_to_E_even) grant_S_to_E_even  = 1;
                else if(req_W_to_E_even) grant_W_to_E_even  = 1;
                else if(req_PE_to_E_even) grant_PE_to_E_even = 1;
                else if(req_N_to_E_even) grant_N_to_E_even  = 1;
            end
            2'd2: begin
                if(req_W_to_E_even) grant_W_to_E_even  = 1;
                else if(req_PE_to_E_even) grant_PE_to_E_even = 1;
                else if(req_N_to_E_even) grant_N_to_E_even  = 1;
                else if(req_S_to_E_even) grant_S_to_E_even  = 1;
            end
            2'd3: begin
                if(req_PE_to_E_even) grant_PE_to_E_even = 1;
                else if(req_N_to_E_even) grant_N_to_E_even  = 1;
                else if(req_S_to_E_even) grant_S_to_E_even  = 1;
                else if(req_W_to_E_even) grant_W_to_E_even  = 1;
            end
        endcase
    end
end


// ================================================================================
//                                       West output
// ================================================================================

reg [63:0] w_out_odd_reg, w_out_even_reg;
reg w_out_odd_full, w_out_even_full;
reg [1:0] w_odd_priority, w_even_priority;

// ---------------------------------- Odd ----------------------------------
wire req_N_to_W_odd  = n_odd_req_W;
wire req_S_to_W_odd  = s_odd_req_W;
wire req_E_to_W_odd  = e_odd_req_W;
wire req_PE_to_W_odd = pe_odd_req_W;

reg grant_N_to_W_odd, grant_S_to_W_odd, grant_E_to_W_odd, grant_PE_to_W_odd;

always@(posedge clk)begin
	if(rst)begin
		w_out_odd_reg <= 0;
		w_out_odd_full <= 0;
		w_odd_priority <= 0;
	end
	else begin
		if(grant_N_to_W_odd)begin
            w_out_odd_reg <= {north_odd_reg[63:56], north_odd_reg[55:52]-4'd1, north_odd_reg[51:0]};
            w_out_odd_full <= 1;
            w_odd_priority <= 2'd1; 
        end
        else if(grant_S_to_W_odd)begin
            w_out_odd_reg <= {south_odd_reg[63:56], south_odd_reg[55:52]-4'd1, south_odd_reg[51:0]};
            w_out_odd_full <= 1;
            w_odd_priority <= 2'd2; 
        end
        else if(grant_E_to_W_odd)begin
            w_out_odd_reg <= {east_odd_reg[63:56], east_odd_reg[55:52]-4'd1, east_odd_reg[51:0]};
            w_out_odd_full <= 1;
            w_odd_priority <= 2'd3; 
        end
        else if(grant_PE_to_W_odd)begin
            w_out_odd_reg <= {pe_odd_reg[63:56], pe_odd_reg[55:52]-4'd1, pe_odd_reg[51:0]};
            w_out_odd_full <= 1;
            w_odd_priority <= 2'd0; 
        end
        else if(polarity == 1'b0 && w_out_odd_full && wro)begin
            w_out_odd_full <= 0;
        end
	end
end

always@(*)begin
	grant_N_to_W_odd = 0;
	grant_S_to_W_odd = 0;
	grant_E_to_W_odd = 0;
	grant_PE_to_W_odd = 0;
	
	if(!w_out_odd_full && polarity == 1'b1)begin
        case (w_odd_priority)
            2'd0: begin 
                if(req_N_to_W_odd) grant_N_to_W_odd  = 1;
                else if(req_S_to_W_odd) grant_S_to_W_odd  = 1;
                else if(req_E_to_W_odd) grant_E_to_W_odd  = 1;
                else if(req_PE_to_W_odd) grant_PE_to_W_odd = 1;
            end
            2'd1: begin
                if(req_S_to_W_odd) grant_S_to_W_odd  = 1;
                else if(req_E_to_W_odd) grant_E_to_W_odd  = 1;
                else if(req_PE_to_W_odd) grant_PE_to_W_odd = 1;
                else if(req_N_to_W_odd) grant_N_to_W_odd  = 1;
            end
            2'd2: begin
                if(req_E_to_W_odd) grant_E_to_W_odd  = 1;
                else if(req_PE_to_W_odd) grant_PE_to_W_odd = 1;
                else if(req_N_to_W_odd) grant_N_to_W_odd  = 1;
                else if(req_S_to_W_odd) grant_S_to_W_odd  = 1;
            end
            2'd3: begin
                if(req_PE_to_W_odd) grant_PE_to_W_odd = 1;
                else if(req_N_to_W_odd) grant_N_to_W_odd  = 1;
                else if(req_S_to_W_odd) grant_S_to_W_odd  = 1;
                else if(req_E_to_W_odd) grant_E_to_W_odd  = 1;
            end
        endcase
    end
end

// ---------------------------------- Even ----------------------------------
wire req_N_to_W_even  = n_even_req_W;
wire req_S_to_W_even  = s_even_req_W;
wire req_E_to_W_even  = e_even_req_W;
wire req_PE_to_W_even = pe_even_req_W;

reg grant_N_to_W_even, grant_S_to_W_even, grant_E_to_W_even, grant_PE_to_W_even;

always@(posedge clk)begin
	if(rst)begin
		w_out_even_reg <= 0;
		w_out_even_full <= 0;
		w_even_priority <= 0;
	end
	else begin
		if(grant_N_to_W_even)begin
            w_out_even_reg <= {north_even_reg[63:56], north_even_reg[55:52]-4'd1, north_even_reg[51:0]};
            w_out_even_full <= 1;
            w_even_priority <= 2'd1; 
        end
        else if(grant_S_to_W_even)begin
            w_out_even_reg <= {south_even_reg[63:56], south_even_reg[55:52]-4'd1, south_even_reg[51:0]};
            w_out_even_full <= 1;
            w_even_priority <= 2'd2; 
        end
        else if(grant_E_to_W_even)begin
            w_out_even_reg <= {east_even_reg[63:56], east_even_reg[55:52]-4'd1, east_even_reg[47:0]};
            w_out_even_full <= 1;
            w_even_priority <= 2'd3; 
        end
        else if(grant_PE_to_W_even)begin
            w_out_even_reg <= {pe_even_reg[63:56], pe_even_reg[55:52]-4'd1, pe_even_reg[51:0]};
            w_out_even_full <= 1;
            w_even_priority <= 2'd0; 
        end
        else if(polarity == 1'b1 && w_out_even_full && wro)begin
            w_out_even_full <= 0;
        end
	end
end

always@(*)begin
	grant_N_to_W_even = 0;
	grant_S_to_W_even = 0;
	grant_E_to_W_even = 0;
	grant_PE_to_W_even = 0;
	
	if(!w_out_even_full && polarity == 1'b0)begin
        case (w_even_priority)
            2'd0: begin 
                if(req_N_to_W_even) grant_N_to_W_even  = 1;
                else if(req_S_to_W_even) grant_S_to_W_even  = 1;
                else if(req_E_to_W_even) grant_E_to_W_even  = 1;
                else if(req_PE_to_W_even) grant_PE_to_W_even = 1;
            end
            2'd1: begin
                if(req_S_to_W_even) grant_S_to_W_even  = 1;
                else if(req_E_to_W_even) grant_E_to_W_even  = 1;
                else if(req_PE_to_W_even) grant_PE_to_W_even = 1;
                else if(req_N_to_W_even) grant_N_to_W_even  = 1;
            end
            2'd2: begin
                if(req_E_to_W_even) grant_E_to_W_even  = 1;
                else if(req_PE_to_W_even) grant_PE_to_W_even = 1;
                else if(req_N_to_W_even) grant_N_to_W_even  = 1;
                else if(req_S_to_W_even) grant_S_to_W_even  = 1;
            end
            2'd3: begin
                if(req_PE_to_W_even) grant_PE_to_W_even = 1;
                else if(req_N_to_W_even) grant_N_to_W_even  = 1;
                else if(req_S_to_W_even) grant_S_to_W_even  = 1;
                else if(req_E_to_W_even) grant_E_to_W_even  = 1;
            end
        endcase
    end
end


// ================================================================================
//                                       PE output
// ================================================================================

reg [63:0] pe_out_odd_reg, pe_out_even_reg;
reg pe_out_odd_full, pe_out_even_full;
reg [1:0] pe_odd_priority, pe_even_priority;

// ---------------------------------- Odd ----------------------------------
wire req_N_to_PE_odd = n_odd_req_PE;
wire req_S_to_PE_odd = s_odd_req_PE;
wire req_E_to_PE_odd = e_odd_req_PE;
wire req_W_to_PE_odd = w_odd_req_PE;

reg grant_N_to_PE_odd, grant_S_to_PE_odd, grant_E_to_PE_odd, grant_W_to_PE_odd;

always@(posedge clk)begin
	if(rst)begin
		pe_out_odd_reg <= 0;
		pe_out_odd_full <= 0;
		pe_odd_priority <= 0;
	end
	else begin
		if(grant_N_to_PE_odd)begin
            pe_out_odd_reg <= north_odd_reg;  // deliver to PE: no hop decrement
            pe_out_odd_full <= 1;
            pe_odd_priority <= 2'd1; 
        end
        else if(grant_S_to_PE_odd)begin
            pe_out_odd_reg <= south_odd_reg;
            pe_out_odd_full <= 1;
            pe_odd_priority <= 2'd2; 
        end
        else if(grant_E_to_PE_odd)begin
            pe_out_odd_reg <= east_odd_reg;
            pe_out_odd_full <= 1;
            pe_odd_priority <= 2'd3; 
        end
        else if(grant_W_to_PE_odd)begin
            pe_out_odd_reg <= west_odd_reg;
            pe_out_odd_full <= 1;
            pe_odd_priority <= 2'd0; 
        end
        else if(polarity == 1'b0 && pe_out_odd_full && pero)begin
            pe_out_odd_full <= 0;
        end
	end
end

always@(*)begin
	grant_N_to_PE_odd = 0;
	grant_S_to_PE_odd = 0;
	grant_E_to_PE_odd = 0;
	grant_W_to_PE_odd = 0;
	
	if(!pe_out_odd_full && polarity == 1'b1)begin
        case (pe_odd_priority)
            2'd0: begin 
                if(req_N_to_PE_odd) grant_N_to_PE_odd  = 1;
                else if(req_S_to_PE_odd) grant_S_to_PE_odd  = 1;
                else if(req_E_to_PE_odd) grant_E_to_PE_odd  = 1;
                else if(req_W_to_PE_odd) grant_W_to_PE_odd = 1;
            end
            2'd1: begin
                if(req_S_to_PE_odd) grant_S_to_PE_odd  = 1;
                else if(req_E_to_PE_odd) grant_E_to_PE_odd  = 1;
                else if(req_W_to_PE_odd) grant_W_to_PE_odd = 1;
                else if(req_N_to_PE_odd) grant_N_to_PE_odd  = 1;
            end
            2'd2: begin
                if(req_E_to_PE_odd) grant_E_to_PE_odd  = 1;
                else if(req_W_to_PE_odd) grant_W_to_PE_odd = 1;
                else if(req_N_to_PE_odd) grant_N_to_PE_odd  = 1;
                else if(req_S_to_PE_odd) grant_S_to_PE_odd  = 1;
            end
            2'd3: begin
                if(req_W_to_PE_odd) grant_W_to_PE_odd = 1;
                else if(req_N_to_PE_odd) grant_N_to_PE_odd  = 1;
                else if(req_S_to_PE_odd) grant_S_to_PE_odd  = 1;
                else if(req_E_to_PE_odd) grant_E_to_PE_odd  = 1;
            end
        endcase
    end
end

// ---------------------------------- Even ----------------------------------
wire req_N_to_PE_even = n_even_req_PE;
wire req_S_to_PE_even = s_even_req_PE;
wire req_E_to_PE_even = e_even_req_PE;
wire req_W_to_PE_even = w_even_req_PE;

reg grant_N_to_PE_even, grant_S_to_PE_even, grant_E_to_PE_even, grant_W_to_PE_even;

always@(posedge clk)begin
	if(rst)begin
		pe_out_even_reg <= 0;
		pe_out_even_full <= 0;
		pe_even_priority <= 0;
	end
	else begin
		if(grant_N_to_PE_even)begin
            pe_out_even_reg <= north_even_reg;
            pe_out_even_full <= 1;
            pe_even_priority <= 2'd1; 
        end
        else if(grant_S_to_PE_even)begin
            pe_out_even_reg <= south_even_reg;
            pe_out_even_full <= 1;
            pe_even_priority <= 2'd2; 
        end
        else if(grant_E_to_PE_even)begin
            pe_out_even_reg <= east_even_reg;
            pe_out_even_full <= 1;
            pe_even_priority <= 2'd3; 
        end
        else if(grant_W_to_PE_even)begin
            pe_out_even_reg <= west_even_reg;
            pe_out_even_full <= 1;
            pe_even_priority <= 2'd0; 
        end
        else if(polarity == 1'b1 && pe_out_even_full && pero)begin
            pe_out_even_full <= 0;
        end
	end
end

always@(*)begin
	grant_N_to_PE_even = 0;
	grant_S_to_PE_even = 0;
	grant_E_to_PE_even = 0;
	grant_W_to_PE_even = 0;
	
	if(!pe_out_even_full && polarity == 1'b0)begin
        case (pe_even_priority)
            2'd0: begin 
                if(req_N_to_PE_even) grant_N_to_PE_even  = 1;
                else if(req_S_to_PE_even) grant_S_to_PE_even  = 1;
                else if(req_E_to_PE_even) grant_E_to_PE_even  = 1;
                else if(req_W_to_PE_even) grant_W_to_PE_even = 1;
            end
            2'd1: begin
                if(req_S_to_PE_even) grant_S_to_PE_even  = 1;
                else if(req_E_to_PE_even) grant_E_to_PE_even  = 1;
                else if(req_W_to_PE_even) grant_W_to_PE_even = 1;
                else if(req_N_to_PE_even) grant_N_to_PE_even  = 1;
            end
            2'd2: begin
                if(req_E_to_PE_even) grant_E_to_PE_even  = 1;
                else if(req_W_to_PE_even) grant_W_to_PE_even = 1;
                else if(req_N_to_PE_even) grant_N_to_PE_even  = 1;
                else if(req_S_to_PE_even) grant_S_to_PE_even  = 1;
            end
            2'd3: begin
                if(req_W_to_PE_even) grant_W_to_PE_even = 1;
                else if(req_N_to_PE_even) grant_N_to_PE_even  = 1;
                else if(req_S_to_PE_even) grant_S_to_PE_even  = 1;
                else if(req_E_to_PE_even) grant_E_to_PE_even  = 1;
            end
        endcase
    end
end


// ================================================================================
//                                Grant Connection
// ================================================================================

assign north_odd_granted  = grant_N_to_S_odd  | grant_N_to_E_odd  | grant_N_to_W_odd  | grant_N_to_PE_odd;
assign north_even_granted = grant_N_to_S_even  | grant_N_to_E_even  | grant_N_to_W_even  | grant_N_to_PE_even;

assign south_odd_granted  = grant_S_to_N_odd  | grant_S_to_E_odd  | grant_S_to_W_odd  | grant_S_to_PE_odd;
assign south_even_granted = grant_S_to_N_even  | grant_S_to_E_even  | grant_S_to_W_even  | grant_S_to_PE_even;

assign east_odd_granted   = grant_E_to_N_odd  | grant_E_to_S_odd  | grant_E_to_W_odd  | grant_E_to_PE_odd;
assign east_even_granted  = grant_E_to_N_even  | grant_E_to_S_even  | grant_E_to_W_even  | grant_E_to_PE_even;

assign west_odd_granted   = grant_W_to_N_odd  | grant_W_to_S_odd  | grant_W_to_E_odd  | grant_W_to_PE_odd;
assign west_even_granted  = grant_W_to_N_even  | grant_W_to_S_even  | grant_W_to_E_even  | grant_W_to_PE_even;

assign pe_odd_granted     = grant_PE_to_N_odd  | grant_PE_to_S_odd  | grant_PE_to_E_odd  | grant_PE_to_W_odd;
assign pe_even_granted    = grant_PE_to_N_even  | grant_PE_to_S_even  | grant_PE_to_E_even  | grant_PE_to_W_even;


// ================================================================================
//                                      Output
// ================================================================================

assign ndo = (polarity == 1'b0) ? n_out_odd_reg  : n_out_even_reg;
assign nso = (polarity == 1'b0) ? n_out_odd_full : n_out_even_full;

assign sdo = (polarity == 1'b0) ? s_out_odd_reg  : s_out_even_reg;
assign sso = (polarity == 1'b0) ? s_out_odd_full : s_out_even_full;

assign edo = (polarity == 1'b0) ? e_out_odd_reg  : e_out_even_reg;
assign eso = (polarity == 1'b0) ? e_out_odd_full : e_out_even_full;

assign wdo = (polarity == 1'b0) ? w_out_odd_reg  : w_out_even_reg;
assign wso = (polarity == 1'b0) ? w_out_odd_full : w_out_even_full;

assign pedo = (polarity == 1'b0) ? pe_out_odd_reg  : pe_out_even_reg;
assign peso = (polarity == 1'b0) ? pe_out_odd_full : pe_out_even_full;


endmodule