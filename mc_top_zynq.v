
// look into mc_reset
// look into clk


`timescale 1 ps / 1 ps

// ZP_top_zynq

`include "bp_common_defines.svh"
`include "bp_be_defines.svh"
`include "bp_me_defines.svh"



module mc_top_zynq

  import bsg_noc_pkg::*; // {P=0, W, E, N, S}
  import bsg_tag_pkg::*;
  import bsg_manycore_pkg::*;
  import bsg_manycore_mem_cfg_pkg::*;
    
#(  
    // from ZP_top_zynq
    , parameter integer C_S00_AXI_DATA_WIDTH   = 32
    , parameter integer C_S00_AXI_ADDR_WIDTH   = 6
	
    // from bp_dram_dummy.v
    , parameter axi_addr_width_p = 32
    , parameter axi_data_width_p = 64
    , parameter axi_id_width_p   = 6
    , parameter axi_len_width_p  = 4
    , parameter axi_size_width_p = 3
    , localparam axi_mask_width_lp = axi_data_width_p>>3
   
  
  
 // ----------------------- DUMMY STARTS  ---------------------------------------------------------------------------------------------------
	
	
	//parameter bp_params_e bp_params_p = e_bp_default_cfg
   //`declare_bp_proc_params(bp_params_p)
   //`declare_bp_bedrock_mem_if_widths(paddr_width_p, did_width_p, lce_id_width_p, lce_assoc_p)
	
	
   // , `BSG_INV_PARAM(icache_block_size_in_words_p)
    //, credit_counter_width_p = `BSG_WIDTH(32)
    //, warn_out_of_credits_p  = 1		
    // size of outgoing response fifo
    //, rev_fifo_els_p         = 3
    //, localparam lg_rev_fifo_els_lp     = `BSG_WIDTH(rev_fifo_els_p)

    // fwd fifo interface
    //, parameter use_credits_for_local_fifo_p = 0

	// ----------------------- DUMMY ENDS  ---------------------------------------------------
	

   
   
 )
( 
//======================== ZYNQSHELL GPIO-0 ========================

     input wire                                  s00_axi_aclk
   , input wire                                  s00_axi_aresetn
   , input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr
   , input wire [2 : 0]                          s00_axi_awprot
   , input wire                                  s00_axi_awvalid
   , output wire                                 s00_axi_awready
   , input wire [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata
   , input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb
   , input wire                                  s00_axi_wvalid
   , output wire                                 s00_axi_wready
   , output wire [1 : 0]                         s00_axi_bresp
   , output wire                                 s00_axi_bvalid
   , input wire                                  s00_axi_bready
   , input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr
   , input wire [2 : 0]                          s00_axi_arprot
   , input wire                                  s00_axi_arvalid
   , output wire                                 s00_axi_arready
   , output wire [C_S00_AXI_DATA_WIDTH-1 : 0]    s00_axi_rdata
   , output wire [1 : 0]                         s00_axi_rresp
   , output wire                                 s00_axi_rvalid
   , input wire                                  s00_axi_rready
   
   
     
   	   //======================== Outgoing Memory ========================
	   	   
   , input wire                                m00_axi_aclk
   , input wire                                m00_axi_aresetn
   
   , output logic [axi_addr_width_p-1:0]       m00_axi_awaddr
   , output logic                              m00_axi_awvalid
   , input                                     m00_axi_awready
   , output logic [axi_id_width_p-1:0]         m00_axi_awid
   , output logic [1:0]                        m00_axi_awlock
   , output logic [3:0]                        m00_axi_awcache
   , output logic [2:0]                        m00_axi_awprot
   , output logic [axi_len_width_p-1:0]        m00_axi_awlen
   , output logic [axi_size_width_p-1:0]       m00_axi_awsize
   , output logic [1:0]                        m00_axi_awburst
   , output logic [3:0]                        m00_axi_awqos  
   
   , output logic [axi_data_width_p-1:0]       m00_axi_wdata
   , output logic                              m00_axi_wvalid
   , input                                     m00_axi_wready
   , output logic [axi_id_width_p-1:0]         m00_axi_wid
   , output logic                              m00_axi_wlast
   , output logic [axi_mask_width_lp-1:0]      m00_axi_wstrb 
   
   , input                                     m00_axi_bvalid
   , output logic                              m00_axi_bready
   , input [axi_id_width_p-1:0]                m00_axi_bid
   , input [1:0]                               m00_axi_bresp 
   
   , output logic [axi_addr_width_p-1:0]       m00_axi_araddr
   , output logic                              m00_axi_arvalid
   , input                                     m00_axi_arready
   , output logic [axi_id_width_p-1:0]         m00_axi_arid
   , output logic [1:0]                        m00_axi_arlock
   , output logic [3:0]                        m00_axi_arcache
   , output logic [2:0]                        m00_axi_arprot
   , output logic [axi_len_width_p-1:0]        m00_axi_arlen
   , output logic [axi_size_width_p-1:0]       m00_axi_arsize
   , output logic [1:0]                        m00_axi_arburst
   , output logic [3:0]                        m00_axi_arqos 
   
   , input [axi_data_width_p-1:0]              m00_axi_rdata
   , input                                     m00_axi_rvalid
   , output logic                              m00_axi_rready
   , input [axi_id_width_p-1:0]                m00_axi_rid
   , input                                     m00_axi_rlast
   , input [1:0]                               m00_axi_rresp
	
);



//----------------------- PARAMETERS MC WRAPPER STARTS------------------------------------------------------------------------------------------------


  parameter num_pods_x_p  		= `BSG_MACHINE_PODS_X;
  parameter num_pods_y_p  		= `BSG_MACHINE_PODS_Y;
  parameter num_tiles_x_p 		= `BSG_MACHINE_GLOBAL_X;
  parameter num_tiles_y_p 		= `BSG_MACHINE_GLOBAL_Y;
  parameter x_cord_width_p 		= `BSG_MACHINE_X_CORD_WIDTH;
  parameter y_cord_width_p 		= `BSG_MACHINE_Y_CORD_WIDTH;
  parameter pod_x_cord_width_p 	= x_cord_width_p - `BSG_SAFE_CLOG2(num_tiles_x_p);
  parameter pod_y_cord_width_p 	= y_cord_width_p - `BSG_SAFE_CLOG2(num_tiles_y_p);
  parameter num_subarray_x_p 	= `BSG_MACHINE_SUBARRAY_X;
  parameter num_subarray_y_p 	= `BSG_MACHINE_SUBARRAY_Y;
  parameter data_width_p 		= 32;
  parameter addr_width_p 		= `BSG_MACHINE_MAX_EPA_WIDTH; // word addr
  parameter dmem_size_p 		= 1024;
  parameter icache_entries_p 	= 1024;
  parameter icache_tag_width_p  = 12;
  parameter icache_block_size_in_words_p = 4;
  parameter ruche_factor_X_p    = `BSG_MACHINE_RUCHE_FACTOR_X;
  parameter barrier_ruche_factor_X_p    = `BSG_MACHINE_BARRIER_RUCHE_FACTOR_X;

  parameter num_vcache_rows_p = `BSG_MACHINE_NUM_VCACHE_ROWS;
  parameter vcache_data_width_p = data_width_p;
  parameter vcache_sets_p = `BSG_MACHINE_VCACHE_SET;
  parameter vcache_ways_p = `BSG_MACHINE_VCACHE_WAY;
  parameter vcache_block_size_in_words_p = `BSG_MACHINE_VCACHE_BLOCK_SIZE_WORDS; // in words
  parameter vcache_dma_data_width_p = `BSG_MACHINE_VCACHE_DMA_DATA_WIDTH; // in bits
  parameter vcache_size_p = vcache_sets_p*vcache_ways_p*vcache_block_size_in_words_p;
  parameter vcache_addr_width_p=(addr_width_p-1+`BSG_SAFE_CLOG2(data_width_p>>3));  // in bytes
  parameter num_vcaches_per_channel_p = `BSG_MACHINE_NUM_VCACHES_PER_CHANNEL;  


  parameter wh_flit_width_p = vcache_dma_data_width_p;
  parameter wh_ruche_factor_p = 2;
  parameter wh_cid_width_p = `BSG_SAFE_CLOG2(2*wh_ruche_factor_p); // no concentration in this testbench; cid is ignored.
  parameter wh_len_width_p = `BSG_SAFE_CLOG2(1+(vcache_block_size_in_words_p*vcache_data_width_p/vcache_dma_data_width_p)); // header + addr + data
  parameter wh_cord_width_p = x_cord_width_p;

  parameter bsg_dram_size_p = `BSG_MACHINE_DRAM_SIZE_WORDS; // in words
  parameter bsg_dram_included_p = `BSG_MACHINE_DRAM_INCLUDED;
  parameter bsg_manycore_mem_cfg_e bsg_manycore_mem_cfg_p = `BSG_MACHINE_MEM_CFG;
  parameter reset_depth_p = 3;



  parameter packet_width_lp = `bsg_manycore_packet_width(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p);
  parameter return_packet_width_lp = `bsg_manycore_return_packet_width(x_cord_width_p,y_cord_width_p,data_width_p);
  parameter link_sif_width_lp = `bsg_manycore_link_sif_width(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p);
 
	

//----------------------- PARAMETERS MC WRAPPER ENDS-------------------------------------------------------------------------------------------------




   // As specified in many_core_io_complex
   localparam max_out_credits_p = 200;
   localparam credit_counter_width_p=`BSG_WIDTH(max_out_credits_p);
   
   logic [credit_counter_width_lp-1:0] out_credits_used_lo;


   logic [2:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_lo;	  
   wire mc_reset = (~csr_data_lo[0][0]); //................

		
   localparam num_regs_ps_to_pl_p = 4     
   localparam num_regs_pl_to_ps_p = 4   
   localparam num_fifo_ps_to_pl_p = 6     
   localparam num_fifo_pl_to_ps_p = 6  
   
   logic [num_fifo_pl_to_ps_p-1:0][C_S00_AXI_DATA_WIDTH-1:0]    pl_to_ps_fifo_data_li;
   logic [num_fifo_ps_to_pl_p-1:0][C_S00_AXI_DATA_WIDTH-1:0]    ps_to_pl_fifo_data_lo;
   logic [num_fifo_pl_to_ps_p-1:0]                              pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;
   logic [num_fifo_ps_to_pl_p-1:0]                              ps_to_pl_fifo_v_lo, ps_to_pl_fifo_ready_li, ps_to_pl_fifo_yumi_i;
  
// ------------------------------------------------------------------------- END POINT---------------------------------------------------------------------------  
	
	
	  
	logic [link_sif_width_lp-1:0] io_link_sif_li;
	logic [link_sif_width_lp-1:0] io_link_sif_lo;
	
	`declare_bsg_manycore_packet_s(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p); // Initializes MC packets as defined in bsg_manycore_pkg.v
	
	
	bsg_manycore_packet_s out_packet_i; // PS_out_request packet declaration
	logic out_v_i;
	logic out_credit_or_ready_o;
	
	bsg_manycore_packet_s packet_lo; // MC_in_request packet declaration
	logic packet_v_lo;
	logic packet_yumi_li;
	
	bsg_manycore_return_packet_s return_packet_li;
	logic return_packet_v_li;
	
	bsg_manycore_return_packet_s return_packet_lo;
	logic return_packet_v_lo;
	logic return_packet_yumi_li;


	// In_request
	assign pl_to_ps_fifo_data_li[0] = packet_lo[31:0]; 
	assign pl_to_ps_fifo_data_li[1] = packet_lo[63:32]; 
	assign pl_to_ps_fifo_data_li[2] = packet_lo[95:64]; 
	assign pl_to_ps_fifo_data_li[3] = (127-packet_width_lp)'packet_lo[packet_width_lp-1:96]; 
	
	
	// Out_response
	assign return_packet_li[31:0] = ps_to_pl_fifo_data_lo[4]; 
	assign return_packet_li[return_packet_width_lp-1:32] = ps_to_pl_fifo_data_lo[5][return_packet_width_lp-1-32:0];


	// Out_request
	assign out_packet_i[31:0] = ps_to_pl_fifo_data_lo[0]; 
	assign out_packet_i[63:32] = ps_to_pl_fifo_data_lo[1]; 
	assign out_packet_i[95:64] = ps_to_pl_fifo_data_lo[2];
	assign out_packet_i[packet_width_lp-1:96] = ps_to_pl_fifo_data_lo[3][packet_width_lp-1-96:0];  
	
	
	// In_response
	assign pl_to_ps_fifo_data_li[4] = return_packet_lo[31:0]; 
	assign pl_to_ps_fifo_data_li[5] = (63-return_packet_width_lp)'return_packet_lo[return_packet_width_lp-1:32]; 


	// PS to PL signals
	
	logic endpoint_req_v_i, endpoint_rsp_v_i;
	logic endpoint_req_ready_o, endpoint_rsp_ready_o;
	
	
		// Valid signals
	
		assign endpoint_req_v_i = &ps_to_pl_fifo_v_lo[3:0];
		assign endpoint_rsp_v_i = &ps_to_pl_fifo_v_lo[5:4];
	
	
		// Ready signals
	
		assign ps_to_pl_fifo_yumi_i = { 2{endpoint_rsp_ready_o }, 4{endpoint_req_ready_o} } ;
	
	
	// PL to PS signals
	
	logic mc_req_v_o, mc_rsp_v_o;
	logic mc_req_ready_i, mc_rsp_ready_i;
	
		// Valid signals
	
		assign pl_to_ps_fifo_v_li = { 2{mc_rsp_v_o}, 4{mc_req_v_o}};
		
		// ready signals
		
		assign mc_req_ready_i = &pl_to_ps_fifo_ready_lo[3:0];
		assign mc_rsp_ready_i = &pl_to_ps_fifo_ready_lo[5:4];
	
	

bsg_manycore_endpoint_to_fifos
#(
	.fifo_width_p 					( 4*data_width_p				),
	.x_cord_width_p		 		    ( x_cord_width_p                ),
	.y_cord_width_p 			    ( y_cord_width_p                ),
	.addr_width_p 				    ( addr_width_p                  ),
	.data_width_p 				    ( data_width_p                  ),
	.ep_fifo_els_p 				    ( 16							),
	.icache_block_size_in_words_p   ( icache_block_size_in_words_p  )

) eptf
(
  .clk_i					( s00_axi_aclk			),
  .reset_i                  ( mc_reset				),
  
  // in_request
  . mc_req_o                ( packet_lo				),
  . mc_req_v_o              ( mc_req_v_o			),
  . mc_req_ready_i          ( mc_req_ready_i		),
  
  // out_request
  . endpoint_req_i          ( out_packet_i			),
  . endpoint_req_v_i        ( endpoint_req_v_i		),
  . endpoint_req_ready_o    ( endpoint_req_ready_o	),
  
  // in_response
  . mc_rsp_o                ( return_packet_lo		),
  . mc_rsp_v_o              ( mc_rsp_v_o			),
  . mc_rsp_ready_i          ( mc_rsp_ready_i		),
  
  // out_response
  . endpoint_rsp_i          ( return_packet_li		),
  . endpoint_rsp_v_i        ( endpoint_rsp_v_i		),
  . endpoint_rsp_ready_o    ( endpoint_rsp_ready_o	),
  
  . link_sif_i              ( io_link_sif_li		),
  . link_sif_o              ( io_link_sif_lo		),
  
  . global_x_i              ( 8'x00					), 
  . global_y_i              ( 8'x01 				),
  
  . out_credits_used_o      ( )

  );





//--------------------------------------------- ZYNQ SHELL -------------------------------------------------------------------------------------------------

	logic [127:0] mem_profiler_r; //......................................
	//logic tag_done_lo;
	
	logic tag_done_lo;
	bsg_tag_s [num_pods_y_p-1:0][num_pods_x_p-1:0] pod_tags_lo;
	

   // Connect Shell to AXI Bus Interface S00_AXI
   bsg_zynq_pl_shell #
     (
       .num_regs_ps_to_pl_p(num_regs_ps_to_pl_p)
      ,.num_fifo_ps_to_pl_p(num_fifo_ps_to_pl_p)
      ,.num_fifo_pl_to_ps_p(num_fifo_pl_to_ps_p)
      ,.num_regs_pl_to_ps_p(num_regs_pl_to_ps_p)
	  
      ,.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
      ,.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
      ) 
	  ZPS
      (
         .csr_data_o(csr_data_lo)
        ,.csr_data_i({ mem_profiler_r[127:96]
                       , mem_profiler_r[95:64]
                       , mem_profiler_r[63:32]
                       , mem_profiler_r[31:0]
					   }
                     )

        ,.pl_to_ps_fifo_data_i (pl_to_ps_fifo_data_li)
        ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li)
        ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo)

        ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo)
        ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo)
        ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_i)

        ,.S_AXI_ACLK   (s00_axi_aclk)
        ,.S_AXI_ARESETN(s00_axi_aresetn)
        ,.S_AXI_AWADDR (s00_axi_awaddr)
        ,.S_AXI_AWPROT (s00_axi_awprot)
        ,.S_AXI_AWVALID(s00_axi_awvalid)
        ,.S_AXI_AWREADY(s00_axi_awready)
        ,.S_AXI_WDATA  (s00_axi_wdata)
        ,.S_AXI_WSTRB  (s00_axi_wstrb)
        ,.S_AXI_WVALID (s00_axi_wvalid)
        ,.S_AXI_WREADY (s00_axi_wready)
        ,.S_AXI_BRESP  (s00_axi_bresp)
        ,.S_AXI_BVALID (s00_axi_bvalid)
        ,.S_AXI_BREADY (s00_axi_bready)
        ,.S_AXI_ARADDR (s00_axi_araddr)
        ,.S_AXI_ARPROT (s00_axi_arprot)
        ,.S_AXI_ARVALID(s00_axi_arvalid)
        ,.S_AXI_ARREADY(s00_axi_arready)
        ,.S_AXI_RDATA  (s00_axi_rdata)
        ,.S_AXI_RRESP  (s00_axi_rresp)
        ,.S_AXI_RVALID (s00_axi_rvalid)
        ,.S_AXI_RREADY (s00_axi_rready)
					
		,.pod_tags_lo	  ( pod_tags_lo	)
		,.tag_done_lo	  ( tag_done_lo	)
		
        );



   bsg_dff_reset #(.width_p(128)) dff
     (.clk_i() //.................
      ,.reset_i(mc_reset)
      ,.data_i(mem_profiler_r
               | m00_axi_awvalid << (axi_awaddr[29-:7])
               | m00_axi_arvalid << (axi_araddr[29-:7])
               )
      ,.data_o(mem_profiler_r)
      );
 
    logic [axi_addr_width_p-1:0] axi_awaddr;
   logic [axi_addr_width_p-1:0] axi_araddr;
   
   localparam debug_lp = 0;
   localparam memory_upper_limit_lp = 120*1024*1024;


always @(negedge s01_axi_aclk)
     if (m00_axi_arvalid & m00_axi_arready)
       if (debug_lp) $display("MC AXI Write Addr %x -> %x (AXI HP0)",axi_araddr,m00_axi_araddr);
 
//---------------------------------------------------- AXI_M00 Address LOGIC -------------------------------------------------------------------------------------



   always @(negedge s01_axi_aclk)
     begin
        if (m00_axi_awvalid && ((axi_awaddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
          $display("Error in DRAM write: %x",axi_awaddr);
        if (m00_axi_arvalid && ((axi_araddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
          $display("Error in DRAM read: %x",axi_araddr);
     end

   assign m00_axi_awaddr = (axi_awaddr ^ 32'h8000_0000) + csr_data_lo[2]; 
   assign m00_axi_araddr = (axi_araddr ^ 32'h8000_0000) + csr_data_lo[2];


   always @(negedge m00_axi_aclk)
     if (m00_axi_awvalid & m00_axi_awready)
       if (debug_lp) $display("MC AXI Write Addr %x -> %x (AXI HP0)",axi_awaddr,m00_axi_awaddr);


// --------------------------------------------------------- MC CORE ---------------------------------------------------------------------------------------- 

// MC top wrapper

mc_wrapper 
  #(
     .num_pods_x_p(num_pods_x_p)
    ,.num_pods_y_p(num_pods_y_p)
    ,.num_tiles_x_p(num_tiles_x_p)
    ,.num_tiles_y_p(num_tiles_y_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.pod_x_cord_width_p(pod_x_cord_width_p)
    ,.pod_y_cord_width_p(pod_y_cord_width_p)
    ,.addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.dmem_size_p(dmem_size_p)
    ,.icache_entries_p(icache_entries_p)
    ,.icache_tag_width_p(icache_tag_width_p)
    ,.icache_block_size_in_words_p(icache_block_size_in_words_p)
    ,.ruche_factor_X_p(ruche_factor_X_p)
    ,.barrier_ruche_factor_X_p(barrier_ruche_factor_X_p)

    ,.num_subarray_x_p(num_subarray_x_p)
    ,.num_subarray_y_p(num_subarray_y_p)

    ,.num_vcache_rows_p(num_vcache_rows_p)
    ,.vcache_data_width_p(vcache_data_width_p)
    ,.vcache_sets_p(vcache_sets_p)
    ,.vcache_ways_p(vcache_ways_p)
    ,.vcache_block_size_in_words_p(vcache_block_size_in_words_p)
    ,.vcache_dma_data_width_p(vcache_dma_data_width_p)
    ,.vcache_size_p(vcache_size_p)
    ,.vcache_addr_width_p(vcache_addr_width_p)
    ,.num_vcaches_per_channel_p(num_vcaches_per_channel_p)

    ,.wh_flit_width_p(wh_flit_width_p)
    ,.wh_ruche_factor_p(wh_ruche_factor_p)
    ,.wh_cid_width_p(wh_cid_width_p)
    ,.wh_len_width_p(wh_len_width_p)
    ,.wh_cord_width_p(wh_cord_width_p)

    ,.bsg_manycore_mem_cfg_p(bsg_manycore_mem_cfg_p)
    ,.bsg_dram_size_p(bsg_dram_size_p)

    ,.reset_depth_p(reset_depth_p)

///////// EXTRA FEATURES LIKE PROFILING ETC while running SPMD program

`ifdef BSG_ENABLE_PROFILING
    ,.enable_vcore_profiling_p(1)
    ,.enable_router_profiling_p(1)
    ,.enable_cache_profiling_p(1)
    ,.enable_remote_op_profiling_p(1)
`endif
`ifdef BSG_ENABLE_COVERAGE
    ,.enable_vcore_pc_coverage_p(1)
`endif
`ifdef BSG_ENABLE_VANILLA_CORE_TRACE
    ,.enable_vanilla_core_trace_p(1)
`endif
`ifdef BSG_ENABLE_PC_HISTOGRAM
    ,.enable_vanilla_core_pc_histogram_p(1)
`endif
  // DR: If the instance name is changed, the bind statements in the
  // file where this module is defined, and header strings in the
  // profilers need to be changed as well.
	
	
	,.axi_addr_width_p (axi_addr_width_p  )
	,.axi_data_width_p (axi_data_width_p  )
	,.axi_id_width_p   (axi_id_width_p    )
	,.axi_len_width_p  (axi_len_width_p   )
	,.axi_size_width_p (axi_size_width_p  )
	
  ) 
  DUT
  (
    .clk_i			  (	s00_axi_aclk		),
    .reset_i          (	mc_reset			),
    .dram_clk_i       (	s00_axi_aclk		),
    //+.tag_done_o       (	tag_done_lo			),
    .io_link_sif_i    (	io_link_sif_li		),
    .io_link_sif_o    (	io_link_sif_lo		),
	
	
	//======================== Outgoing Memory ========================
	
	.m_axi_awaddr_o	  ( axi_awaddr 			),	
	.m_axi_awvalid_o  ( m00_axi_awvalid		),
	.m_axi_awready_i  ( m00_axi_awready		),
	.m_axi_awid_o     ( m00_axi_awid		),
	.m_axi_awlock_o   ( m00_axi_awlock		),
	.m_axi_awcache_o  ( m00_axi_awcache		),
	.m_axi_awprot_o   ( m00_axi_awprot		),
	.m_axi_awlen_o    ( m00_axi_awlen		),
	.m_axi_awsize_o   ( m00_axi_awsize		),
	.m_axi_awburst_o  ( m00_axi_awburst		),
	.m_axi_awqos_o	  ( m00_axi_awqos  		),	
	
	.m_axi_wdata_o    ( m00_axi_wdata		),
	.m_axi_wvalid_o   ( m00_axi_wvalid		),
	.m_axi_wready_i   ( m00_axi_wready		),
	.m_axi_wid_o      ( m00_axi_wid			),
	.m_axi_wlast_o    ( m00_axi_wlast		),
	.m_axi_wstrb_o	  ( m00_axi_wstrb 		),	
	
	.m_axi_bvalid_i   ( m00_axi_bvalid		),
	.m_axi_bready_o   ( m00_axi_bready		),
	.m_axi_bid_i      ( m00_axi_bid			),
	.m_axi_bresp_i    ( m00_axi_bresp 		),	
	
	.m_axi_araddr_o   ( axi_araddr			),
	.m_axi_arvalid_o  ( m00_axi_arvalid		),
	.m_axi_arready_i  ( m00_axi_arready		),
	.m_axi_arid_o     ( m00_axi_arid		),
	.m_axi_arlock_o   ( m00_axi_arlock		),
	.m_axi_arcache_o  ( m00_axi_arcache		),
	.m_axi_arprot_o   ( m00_axi_arprot		),
	.m_axi_arlen_o    ( m00_axi_arlen		),
	.m_axi_arsize_o   ( m00_axi_arsize		),
	.m_axi_arburst_o  ( m00_axi_arburst		),
	.m_axi_arqos_o	  ( m00_axi_arqos 		),	
	
	.m_axi_rdata_i    ( m00_axi_rdata		),
	.m_axi_rvalid_i   ( m00_axi_rvalid		),
	.m_axi_rready_o   ( m00_axi_rready		),
	.m_axi_rid_i      ( m00_axi_rid			),
	.m_axi_rlast_i    ( m00_axi_rlast		),
	.m_axi_rresp_i    ( m00_axi_rresp		),
	
	
	.pod_tags_lo	  ( pod_tags_lo			),
	.tag_done_lo	  ( tag_done_lo			)

  );


endmodule