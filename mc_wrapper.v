
`include "bsg_manycore_defines.vh"
`include "bsg_cache.vh"

// from bp_dram_dummy.v
`include "bp_common_defines.svh"
`include "bp_me_defines.svh"



module mc_wrapper
  import bsg_noc_pkg::*; // {P=0, W, E, N, S}
  import bsg_tag_pkg::*;
  import bsg_manycore_pkg::*;
  import bsg_manycore_mem_cfg_pkg::*;
  
  // from bp_dram_dummy.v
  import bp_common_pkg::*;
  import bp_me_pkg::*;
  
  
  #(parameter `BSG_INV_PARAM(num_pods_x_p)
    , parameter `BSG_INV_PARAM(num_pods_y_p)
    , parameter `BSG_INV_PARAM(num_tiles_x_p)
    , parameter `BSG_INV_PARAM(num_tiles_y_p)
    , parameter `BSG_INV_PARAM(x_cord_width_p)
    , parameter `BSG_INV_PARAM(y_cord_width_p)
    , parameter `BSG_INV_PARAM(pod_x_cord_width_p)
    , parameter `BSG_INV_PARAM(pod_y_cord_width_p)
    , parameter `BSG_INV_PARAM(addr_width_p)
    , parameter `BSG_INV_PARAM(data_width_p)
    , parameter `BSG_INV_PARAM(dmem_size_p)
    , parameter `BSG_INV_PARAM(icache_entries_p)
    , parameter `BSG_INV_PARAM(icache_tag_width_p)
    , parameter `BSG_INV_PARAM(icache_block_size_in_words_p)
    , parameter `BSG_INV_PARAM(ruche_factor_X_p)
    , parameter `BSG_INV_PARAM(barrier_ruche_factor_X_p)

    , parameter `BSG_INV_PARAM(num_subarray_x_p)
    , parameter `BSG_INV_PARAM(num_subarray_y_p)

    , parameter `BSG_INV_PARAM(num_vcache_rows_p)
    , parameter `BSG_INV_PARAM(vcache_data_width_p)
    , parameter `BSG_INV_PARAM(vcache_sets_p)
    , parameter `BSG_INV_PARAM(vcache_ways_p)
    , parameter `BSG_INV_PARAM(vcache_block_size_in_words_p) // in words
    , parameter `BSG_INV_PARAM(vcache_dma_data_width_p) // in bits
    , parameter `BSG_INV_PARAM(vcache_size_p) // in words
    , parameter `BSG_INV_PARAM(vcache_addr_width_p) // byte addr
    , parameter `BSG_INV_PARAM(num_vcaches_per_channel_p)

    , parameter `BSG_INV_PARAM(wh_flit_width_p)
    , parameter wh_ruche_factor_p = 2
    , parameter `BSG_INV_PARAM(wh_cid_width_p)
    , parameter `BSG_INV_PARAM(wh_len_width_p)
    , parameter `BSG_INV_PARAM(wh_cord_width_p)

    , parameter bsg_manycore_mem_cfg_e bsg_manycore_mem_cfg_p = e_vcache_test_mem
    , parameter `BSG_INV_PARAM(bsg_dram_size_p) // in word
    , parameter reset_depth_p = 3

    , parameter enable_vcore_profiling_p=0
    , parameter enable_router_profiling_p=0
    , parameter enable_cache_profiling_p=0
    , parameter enable_vanilla_core_trace_p = 0
    , parameter enable_remote_op_profiling_p = 0

    , parameter enable_vcore_pc_coverage_p=0

    , parameter enable_vanilla_core_pc_histogram_p=0

    , parameter cache_bank_addr_width_lp = `BSG_SAFE_CLOG2(bsg_dram_size_p/(2*num_tiles_x_p*num_vcache_rows_p)*4) // byte addr
    , parameter link_sif_width_lp = `bsg_manycore_link_sif_width(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p)

    // This is used to define heterogeneous arrays. Each index defines
    // the type of an X/Y coordinate in the array. This is a vector of
    // num_tiles_x_p*num_tiles_y_p ints; type "0" is the
    // default. See bsg_manycore_hetero_socket.v for more types.
    , parameter int hetero_type_vec_p [0:(num_tiles_y_p*num_tiles_x_p) - 1]  = '{default:0}
	
	// from bp_dram_dummy.v
	, parameter axi_addr_width_p = 32
	, parameter axi_data_width_p = 64
	, parameter axi_id_width_p   = 6
	, parameter axi_len_width_p  = 4
	, parameter axi_size_width_p = 3
	, localparam axi_mask_width_lp = axi_data_width_p>>3
	
	
  )
  (
	  input clk_i
    , input reset_i
    , input dram_clk_i
    //, output tag_done_o   
    , input  [link_sif_width_lp-1:0] io_link_sif_i
    , output [link_sif_width_lp-1:0] io_link_sif_o
	
	
	   //======================== Outgoing Memory ========================
	   
	   
   , output logic [axi_addr_width_p-1:0]       m_axi_awaddr_o
   , output logic                              m_axi_awvalid_o
   , input                                     m_axi_awready_i
   , output logic [axi_id_width_p-1:0]         m_axi_awid_o
   , output logic [1:0]                        m_axi_awlock_o
   , output logic [3:0]                        m_axi_awcache_o
   , output logic [2:0]                        m_axi_awprot_o
   , output logic [axi_len_width_p-1:0]        m_axi_awlen_o
   , output logic [axi_size_width_p-1:0]       m_axi_awsize_o
   , output logic [1:0]                        m_axi_awburst_o
   , output logic [3:0]                        m_axi_awqos_o

   , output logic [axi_data_width_p-1:0]       m_axi_wdata_o
   , output logic                              m_axi_wvalid_o
   , input                                     m_axi_wready_i
   , output logic [axi_id_width_p-1:0]         m_axi_wid_o
   , output logic                              m_axi_wlast_o
   , output logic [axi_mask_width_lp-1:0]      m_axi_wstrb_o

   , input                                     m_axi_bvalid_i
   , output logic                              m_axi_bready_o
   , input [axi_id_width_p-1:0]                m_axi_bid_i
   , input [1:0]                               m_axi_bresp_i

   , output logic [axi_addr_width_p-1:0]       m_axi_araddr_o
   , output logic                              m_axi_arvalid_o
   , input                                     m_axi_arready_i
   , output logic [axi_id_width_p-1:0]         m_axi_arid_o
   , output logic [1:0]                        m_axi_arlock_o
   , output logic [3:0]                        m_axi_arcache_o
   , output logic [2:0]                        m_axi_arprot_o
   , output logic [axi_len_width_p-1:0]        m_axi_arlen_o
   , output logic [axi_size_width_p-1:0]       m_axi_arsize_o
   , output logic [1:0]                        m_axi_arburst_o
   , output logic [3:0]                        m_axi_arqos_o

   , input [axi_data_width_p-1:0]              m_axi_rdata_i
   , input                                     m_axi_rvalid_i
   , output logic                              m_axi_rready_o
   , input [axi_id_width_p-1:0]                m_axi_rid_i
   , input                                     m_axi_rlast_i
   , input [1:0]                               m_axi_rresp_i
	
`` , input [???][num_pods_y_p-1:0][num_pods_x_p-1:0] 	pod_tags_lo
   , input logic 							   			tag_done_lo

	
  );


  // print machine settings
  initial begin
    $display("MACHINE SETTINGS:");
    $display("[INFO][TESTBENCH] BSG_MACHINE_GLOBAL_X                 = %d", num_tiles_x_p);
    $display("[INFO][TESTBENCH] BSG_MACHINE_GLOBAL_Y                 = %d", num_tiles_y_p);
    $display("[INFO][TESTBENCH] BSG_MACHINE_VCACHE_SET               = %d", vcache_sets_p);
    $display("[INFO][TESTBENCH] BSG_MACHINE_VCACHE_WAY               = %d", vcache_ways_p);
    $display("[INFO][TESTBENCH] BSG_MACHINE_VCACHE_BLOCK_SIZE_WORDS  = %d", vcache_block_size_in_words_p);
    $display("[INFO][TESTBENCH] BSG_MACHINE_MAX_EPA_WIDTH            = %d", addr_width_p);
    $display("[INFO][TESTBENCH] BSG_MACHINE_MEM_CFG                  = %s", bsg_manycore_mem_cfg_p.name());
    $display("[INFO][TESTBENCH] BSG_MACHINE_RUCHE_FACTOR_X           = %d", ruche_factor_X_p);
    $display("[INFO][TESTBENCH] BSG_MACHINE_BARRIER_RUCHE_FACTOR_X   = %d", barrier_ruche_factor_X_p);
    $display("[INFO][TESTBENCH] BSG_MACHINE_SUBARRAY_X               = %d", num_subarray_x_p);
    $display("[INFO][TESTBENCH] BSG_MACHINE_SUBARRAY_Y               = %d", num_subarray_y_p);
    $display("[INFO][TESTBENCH] BSG_MACHINE_ORIGIN_X_CORD            = %d", `BSG_MACHINE_ORIGIN_X_CORD);
    $display("[INFO][TESTBENCH] BSG_MACHINE_ORIGIN_Y_CORD            = %d", `BSG_MACHINE_ORIGIN_Y_CORD);
    $display("[INFO][TESTBENCH] BSG_MACHINE_NUM_VCACHE_ROWS          = %d", num_vcache_rows_p);
    $display("[INFO][TESTBENCH] enable_vcore_profiling_p             = %d", enable_vcore_profiling_p);
    $display("[INFO][TESTBENCH] enable_router_profiling_p            = %d", enable_router_profiling_p);
    $display("[INFO][TESTBENCH] enable_cache_profiling_p             = %d", enable_cache_profiling_p);
    $display("[INFO][TESTBENCH] enable_vcore_pc_coverage_p           = %d", enable_vcore_pc_coverage_p);
  end


  // BSG TAG MASTER
  //logic tag_done_lo;
  //bsg_tag_s [num_pods_y_p-1:0][num_pods_x_p-1:0] pod_tags_lo;

//bsg_nonsynth_manycore_tag_master #(
  //  .num_pods_x_p(num_pods_x_p)
    //,.num_pods_y_p(num_pods_y_p)
//    ,.wh_cord_width_p(wh_cord_width_p)
  //) mtm (
    //.clk_i(clk_i)
   // ,.reset_i(reset_i)
    
    //,.tag_done_o(tag_done_lo)
    //,.pod_tags_o(pod_tags_lo)
  //);   
  
  //assign tag_done_o = tag_done_lo;

  // deassert reset when tag programming is done.
  wire reset = ~tag_done_lo;
  logic reset_r;
  bsg_dff_chain #(
    .width_p(1)
    ,.num_stages_p(reset_depth_p)
  ) reset_dff (
    .clk_i(clk_i)
    ,.data_i(reset)
    ,.data_o(reset_r)
  );

  logic dram_reset_r;
  bsg_sync_sync #(.width_p(1)) dram_reset_bss (
    .oclk_i(dram_clk_i)
    ,.iclk_data_i(reset_r)
    ,.oclk_data_o(dram_reset_r)
  );


  // instantiate manycore
  `declare_bsg_manycore_link_sif_s(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p);
  `declare_bsg_manycore_ruche_x_link_sif_s(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p);
  `declare_bsg_ready_and_link_sif_s(wh_flit_width_p, wh_link_sif_s);
  bsg_manycore_link_sif_s [S:N][(num_pods_x_p*num_tiles_x_p)-1:0] ver_link_sif_li;
  bsg_manycore_link_sif_s [S:N][(num_pods_x_p*num_tiles_x_p)-1:0] ver_link_sif_lo;
  wh_link_sif_s [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0] wh_link_sif_li;
  wh_link_sif_s [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0] wh_link_sif_lo;
  bsg_manycore_link_sif_s [E:W][num_pods_y_p-1:0][num_tiles_y_p-1:0] hor_link_sif_li;
  bsg_manycore_link_sif_s [E:W][num_pods_y_p-1:0][num_tiles_y_p-1:0] hor_link_sif_lo;
  bsg_manycore_ruche_x_link_sif_s [E:W][num_pods_y_p-1:0][num_tiles_y_p-1:0] ruche_link_li;
  bsg_manycore_ruche_x_link_sif_s [E:W][num_pods_y_p-1:0][num_tiles_y_p-1:0] ruche_link_lo;

  bsg_manycore_pod_ruche_array #(
    .num_tiles_x_p(num_tiles_x_p)
    ,.num_tiles_y_p(num_tiles_y_p)
    ,.pod_x_cord_width_p(pod_x_cord_width_p)
    ,.pod_y_cord_width_p(pod_y_cord_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.ruche_factor_X_p(ruche_factor_X_p)
    ,.barrier_ruche_factor_X_p(barrier_ruche_factor_X_p)
    ,.num_subarray_x_p(num_subarray_x_p)
    ,.num_subarray_y_p(num_subarray_y_p)

    ,.dmem_size_p(dmem_size_p)
    ,.icache_entries_p(icache_entries_p)
    ,.icache_tag_width_p(icache_tag_width_p)
    ,.icache_block_size_in_words_p(icache_block_size_in_words_p)

    ,.num_vcache_rows_p(num_vcache_rows_p)
    ,.vcache_addr_width_p(vcache_addr_width_p)
    ,.vcache_data_width_p(vcache_data_width_p)
    ,.vcache_ways_p(vcache_ways_p)
    ,.vcache_sets_p(vcache_sets_p)
    ,.vcache_block_size_in_words_p(vcache_block_size_in_words_p)
    ,.vcache_size_p(vcache_size_p)
    ,.vcache_dma_data_width_p(vcache_dma_data_width_p)

    ,.wh_ruche_factor_p(wh_ruche_factor_p)
    ,.wh_cid_width_p(wh_cid_width_p)
    ,.wh_flit_width_p(wh_flit_width_p)
    ,.wh_cord_width_p(wh_cord_width_p)
    ,.wh_len_width_p(wh_len_width_p)

    ,.num_pods_y_p(num_pods_y_p)
    ,.num_pods_x_p(num_pods_x_p)

    ,.reset_depth_p(reset_depth_p)
    ,.hetero_type_vec_p(hetero_type_vec_p)
  ) DUT (
    .clk_i(clk_i)

    ,.ver_link_sif_i(ver_link_sif_li)
    ,.ver_link_sif_o(ver_link_sif_lo)

    ,.wh_link_sif_i(wh_link_sif_li)
    ,.wh_link_sif_o(wh_link_sif_lo)

    ,.hor_link_sif_i(hor_link_sif_li)
    ,.hor_link_sif_o(hor_link_sif_lo)

    ,.ruche_link_i(ruche_link_li)
    ,.ruche_link_o(ruche_link_lo)

    ,.pod_tags_i(pod_tags_lo) 
  );


  // IO ROUTER
  localparam rev_use_credits_lp = 5'b00001;
  localparam int rev_fifo_els_lp[4:0] = '{2,2,2,2,3};
  bsg_manycore_link_sif_s [(num_pods_x_p*num_tiles_x_p)-1:0][S:P] io_link_sif_li;
  bsg_manycore_link_sif_s [(num_pods_x_p*num_tiles_x_p)-1:0][S:P] io_link_sif_lo;

  for (genvar x = 0; x < num_pods_x_p*num_tiles_x_p; x++) begin: io_rtr_x
    bsg_manycore_mesh_node #(
      .x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.stub_p(4'b0100) // stub north
      ,.rev_use_credits_p(rev_use_credits_lp)
      ,.rev_fifo_els_p(rev_fifo_els_lp)
    ) io_rtr (
      .clk_i(clk_i)
      ,.reset_i(reset_r)

      ,.links_sif_i(io_link_sif_li[x][S:W])
      ,.links_sif_o(io_link_sif_lo[x][S:W])

      ,.proc_link_sif_i(io_link_sif_li[x][P])
      ,.proc_link_sif_o(io_link_sif_lo[x][P])

      ,.global_x_i(x_cord_width_p'(num_tiles_x_p+x))
      ,.global_y_i(y_cord_width_p'(0))
    );

    // connect to pod array
    assign ver_link_sif_li[N][x] = io_link_sif_lo[x][S];
    assign io_link_sif_li[x][S] = ver_link_sif_lo[N][x];

    // connect between io rtr
    if (x < (num_pods_x_p*num_tiles_x_p)-1) begin
      assign io_link_sif_li[x][E] = io_link_sif_lo[x+1][W];
      assign io_link_sif_li[x+1][W] = io_link_sif_lo[x][E];
    end
  end



  // Host link connection
  assign io_link_sif_li[0][P] = io_link_sif_i; //.. External INPUT
  assign io_link_sif_o = io_link_sif_lo[0][P];





  //                              //
  // Configurable Memory System   //
  //                              //
  
  
  // Invert WH ruche links
  // hardcoded for ruche factor = 2
  wh_link_sif_s [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0] buffered_wh_link_sif_li;
  wh_link_sif_s [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0] buffered_wh_link_sif_lo;
  
  
  for (genvar i = W; i <= E; i++) begin
    for (genvar j = 0; j < num_pods_y_p; j++) begin
      for (genvar k = N; k <= S; k++) begin
        for (genvar v = 0; v < num_vcache_rows_p; v++) begin
          for (genvar r = 0; r < wh_ruche_factor_p; r++) begin
            if (r == 0) begin
              assign wh_link_sif_li[i][j][k][v][r] = buffered_wh_link_sif_li[i][j][k][v][r];
              assign buffered_wh_link_sif_lo[i][j][k][v][r] = wh_link_sif_lo[i][j][k][v][r];
            end
            else begin
              assign wh_link_sif_li[i][j][k][v][r] = ~buffered_wh_link_sif_li[i][j][k][v][r];
              assign buffered_wh_link_sif_lo[i][j][k][v][r] = ~wh_link_sif_lo[i][j][k][v][r];
            end
          end
        end
      end
    end
  end
  
  localparam logic [e_max_val-1:0] mem_cfg_lp = (1 << bsg_manycore_mem_cfg_p);

  if (mem_cfg_lp[e_vcache_test_mem]) begin: test_mem
    // in bytes
    // north + south row of vcache
    localparam longint unsigned mem_size_lp = (2**30)*num_pods_x_p/wh_ruche_factor_p/num_vcache_rows_p/2;
    localparam num_vcaches_per_test_mem_lp = (num_tiles_x_p*num_pods_x_p)/wh_ruche_factor_p/2;

    for (genvar i = W; i <= E; i++) begin: hs                           // horizontal side
      for (genvar j = 0; j < num_pods_y_p; j++) begin: py               // pod y
        for (genvar k = N; k <= S; k++) begin: vs                       // vertical side
          for (genvar v = 0; v < num_vcache_rows_p; v++) begin: vr      // vcache row
            for (genvar r = 0; r < wh_ruche_factor_p; r++) begin: rf    // ruching
              bsg_nonsynth_wormhole_test_mem #(
                .vcache_data_width_p(vcache_data_width_p)
                ,.vcache_dma_data_width_p(vcache_dma_data_width_p)
                ,.vcache_block_size_in_words_p(vcache_block_size_in_words_p)
                ,.num_vcaches_p(num_vcaches_per_test_mem_lp)
                ,.wh_cid_width_p(wh_cid_width_p)
                ,.wh_flit_width_p(wh_flit_width_p)
                ,.wh_cord_width_p(wh_cord_width_p)
                ,.wh_len_width_p(wh_len_width_p)
                ,.wh_ruche_factor_p(wh_ruche_factor_p)
                ,.no_concentration_p(1)
                ,.mem_size_p(mem_size_lp)
              ) test_mem (
                .clk_i(clk_i)
                ,.reset_i(reset_r)

                ,.wh_link_sif_i(buffered_wh_link_sif_lo[i][j][k][v][r])
                ,.wh_link_sif_o(buffered_wh_link_sif_li[i][j][k][v][r])
              );
            end
          end
        end
      end
    end

  end
  else if (mem_cfg_lp[e_vcache_hbm2]) begin: hbm2
    

    `define dram_pkg `BSG_MACHINE_DRAMSIM3_PKG
    parameter hbm2_data_width_p = `dram_pkg::data_width_p;
    parameter hbm2_channel_addr_width_p = `dram_pkg::channel_addr_width_p;
    parameter hbm2_num_channels_p = `dram_pkg::num_channels_p;
      
    parameter num_total_vcaches_lp = (num_pods_x_p*num_pods_y_p*2*num_tiles_x_p*num_vcache_rows_p);
    parameter lg_num_total_vcaches_lp = `BSG_SAFE_CLOG2(num_total_vcaches_lp);
    parameter num_vcaches_per_link_lp = (num_tiles_x_p*num_pods_x_p)/wh_ruche_factor_p/2; // # of vcaches attached to each link

    parameter num_total_channels_lp = num_total_vcaches_lp/num_vcaches_per_channel_p;
    parameter num_dram_lp = `BSG_CDIV(num_total_channels_lp,hbm2_num_channels_p);

    parameter lg_wh_ruche_factor_lp = `BSG_SAFE_CLOG2(wh_ruche_factor_p);
    parameter lg_num_vcaches_per_link_lp = `BSG_SAFE_CLOG2(num_vcaches_per_link_lp);

    // WH to cache dma
    `declare_bsg_cache_dma_pkt_s(vcache_addr_width_p);
    bsg_cache_dma_pkt_s [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_pkt_lo;
    logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_pkt_v_lo;
    logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_pkt_yumi_li;

    logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0][vcache_dma_data_width_p-1:0] dma_data_li;
    logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_data_v_li;
    logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_data_ready_lo;

    logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0][vcache_dma_data_width_p-1:0] dma_data_lo;
    logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_data_v_lo;
    logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_data_yumi_li;


    for (genvar i = W; i <= E; i++) begin: hs
      for (genvar j = 0; j < num_pods_y_p; j++) begin: py
        for (genvar k = N; k <= S; k++) begin: py
          for (genvar n = 0; n < num_vcache_rows_p; n++) begin: row
            for (genvar r = 0; r < wh_ruche_factor_p; r++) begin: rf

              `declare_bsg_cache_wh_header_flit_s(wh_flit_width_p,wh_cord_width_p,wh_len_width_p,wh_cid_width_p);
              bsg_cache_wh_header_flit_s header_flit_in;
              assign header_flit_in = buffered_wh_link_sif_lo[i][j][k][n][r];

              wire [lg_num_vcaches_per_link_lp-1:0] dma_id_li =
                header_flit_in.src_cord[lg_wh_ruche_factor_lp+:lg_num_vcaches_per_link_lp];

              bsg_wormhole_to_cache_dma_fanout#(
                .num_dma_p(num_vcaches_per_link_lp)
                ,.dma_addr_width_p(vcache_addr_width_p)
                ,.dma_burst_len_p(vcache_block_size_in_words_p*vcache_data_width_p/vcache_dma_data_width_p)

                ,.wh_flit_width_p(wh_flit_width_p)
                ,.wh_cid_width_p(wh_cid_width_p)
                ,.wh_len_width_p(wh_len_width_p)
                ,.wh_cord_width_p(wh_cord_width_p)
              ) wh_to_dma (
                .clk_i(clk_i)
                ,.reset_i(reset_r)
    
                ,.wh_link_sif_i     (buffered_wh_link_sif_lo[i][j][k][n][r])
                ,.wh_dma_id_i       (dma_id_li)
                ,.wh_link_sif_o     (buffered_wh_link_sif_li[i][j][k][n][r])

                ,.dma_pkt_o         (dma_pkt_lo[i][j][k][n][r])
                ,.dma_pkt_v_o       (dma_pkt_v_lo[i][j][k][n][r])
                ,.dma_pkt_yumi_i    (dma_pkt_yumi_li[i][j][k][n][r])

                ,.dma_data_i        (dma_data_li[i][j][k][n][r])
                ,.dma_data_v_i      (dma_data_v_li[i][j][k][n][r])
                ,.dma_data_ready_and_o (dma_data_ready_lo[i][j][k][n][r])

                ,.dma_data_o        (dma_data_lo[i][j][k][n][r])
                ,.dma_data_v_o      (dma_data_v_lo[i][j][k][n][r])
                ,.dma_data_yumi_i   (dma_data_yumi_li[i][j][k][n][r])
              );
            end
          end
        end
      end
    end


//- ---------------- - - - - - - - - - --          --- ----             ---- ----             ---- ----             --

  // DMA interface from BP to cache2axi
  `declare_bsg_cache_dma_pkt_s(daddr_width_p);
  bsg_cache_dma_pkt_s [num_cce_p-1:0][l2_banks_p-1:0] c2a_dma_pkt_lo;
  logic [num_cce_p-1:0][l2_banks_p-1:0] c2a_dma_pkt_v_lo, c2a_dma_pkt_ready_and_li;
  logic [num_cce_p-1:0][l2_banks_p-1:0][l2_fill_width_p-1:0] c2a_dma_data_lo;
  logic [num_cce_p-1:0][l2_banks_p-1:0] c2a_dma_data_v_lo, c2a_dma_data_ready_and_li;
  logic [num_cce_p-1:0][l2_banks_p-1:0][l2_fill_width_p-1:0] c2a_dma_data_li;
  logic [num_cce_p-1:0][l2_banks_p-1:0] c2a_dma_data_v_li, c2a_dma_data_ready_and_lo;

// Transpose the DMA IDs
      for (genvar i = 0; i < num_cce_p; i++)
        begin : rof1
          for (genvar j = 0; j < l2_banks_p; j++)
            begin : rof2
              localparam col_lp     = i%mc_x_dim_p;
              localparam col_pos_lp = (i/mc_x_dim_p)*l2_banks_p+j;

              assign c2a_dma_pkt_lo[i][j] = dma_pkt_lo[col_lp][col_pos_lp];
              assign c2a_dma_pkt_v_lo[i][j] = dma_pkt_v_lo[col_lp][col_pos_lp];
              assign dma_pkt_yumi_li[col_lp][col_pos_lp] = c2a_dma_pkt_ready_and_li[i][j] & c2a_dma_pkt_v_lo[i][j];

              assign c2a_dma_data_lo[i][j] = dma_data_lo[col_lp][col_pos_lp];
              assign c2a_dma_data_v_lo[i][j] = dma_data_v_lo[col_lp][col_pos_lp];
              assign dma_data_yumi_li[col_lp][col_pos_lp] = c2a_dma_data_ready_and_li[i][j] & c2a_dma_data_v_lo[i][j];

              assign dma_data_li[col_lp][col_pos_lp] = c2a_dma_data_li[i][j];
              assign dma_data_v_li[col_lp][col_pos_lp] = c2a_dma_data_v_li[i][j];
              assign c2a_dma_data_ready_and_lo[i][j] = dma_data_ready_and_lo[col_lp][col_pos_lp];
            end
        end
    end // multicore



  // Unswizzle the dram
  bsg_cache_dma_pkt_s [num_cce_p-1:0][l2_banks_p-1:0] c2a_dma_pkt;
  for (genvar i = 0; i < num_cce_p; i++)
    begin : rof3
      for (genvar j = 0; j < l2_banks_p; j++)
        begin : address_hash
          logic [daddr_width_p-1:0] daddr_lo;
          bp_me_dram_hash_decode
           #(.bp_params_p(bp_params_p))
            dma_addr_hash
            (.daddr_i(c2a_dma_pkt_lo[i][j].addr)
             ,.daddr_o(c2a_dma_pkt[i][j].addr)
             );
          assign c2a_dma_pkt[i][j].write_not_read = c2a_dma_pkt_lo[i][j].write_not_read;
        end
    end

   bsg_cache_to_axi
    #(.addr_width_p(daddr_width_p)
      ,.data_width_p(l2_fill_width_p)
      ,.block_size_in_words_p(l2_block_size_in_fill_p)
      ,.num_cache_p(num_cce_p*l2_banks_p)
      ,.axi_data_width_p(axi_data_width_p)
      ,.axi_id_width_p(axi_id_width_p)
      ,.axi_burst_len_p(l2_block_width_p/axi_data_width_p)
      )
    cache2axi
     (.clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.dma_pkt_i(c2a_dma_pkt)
      ,.dma_pkt_v_i(c2a_dma_pkt_v_lo)
      ,.dma_pkt_yumi_o(c2a_dma_pkt_ready_and_li)

      ,.dma_data_o(c2a_dma_data_li)
      ,.dma_data_v_o(c2a_dma_data_v_li)
      ,.dma_data_ready_i(c2a_dma_data_ready_and_lo)

      ,.dma_data_i(c2a_dma_data_lo)
      ,.dma_data_v_i(c2a_dma_data_v_lo)
      ,.dma_data_yumi_o(c2a_dma_data_ready_and_li)

      ,.axi_awid_o(m_axi_awid_o)
      ,.axi_awaddr_addr_o(m_axi_awaddr_o)
      ,.axi_awlen_o(m_axi_awlen_o)
      ,.axi_awsize_o(m_axi_awsize_o)
      ,.axi_awburst_o(m_axi_awburst_o)
      ,.axi_awcache_o(m_axi_awcache_o)
      ,.axi_awprot_o(m_axi_awprot_o)
      ,.axi_awlock_o(m_axi_awlock_o)
      ,.axi_awvalid_o(m_axi_awvalid_o)
      ,.axi_awready_i(m_axi_awready_i)

      ,.axi_wdata_o(m_axi_wdata_o)
      ,.axi_wstrb_o(m_axi_wstrb_o)
      ,.axi_wlast_o(m_axi_wlast_o)
      ,.axi_wvalid_o(m_axi_wvalid_o)
      ,.axi_wready_i(m_axi_wready_i)

      ,.axi_bid_i(m_axi_bid_i)
      ,.axi_bresp_i(m_axi_bresp_i)
      ,.axi_bvalid_i(m_axi_bvalid_i)
      ,.axi_bready_o(m_axi_bready_o)

      ,.axi_arid_o(m_axi_arid_o)
      ,.axi_araddr_addr_o(m_axi_araddr_o)
      ,.axi_arlen_o(m_axi_arlen_o)
      ,.axi_arsize_o(m_axi_arsize_o)
      ,.axi_arburst_o(m_axi_arburst_o)
      ,.axi_arcache_o(m_axi_arcache_o)
      ,.axi_arprot_o(m_axi_arprot_o)
      ,.axi_arlock_o(m_axi_arlock_o)
      ,.axi_arvalid_o(m_axi_arvalid_o)
      ,.axi_arready_i(m_axi_arready_i)

      ,.axi_rid_i(m_axi_rid_i)
      ,.axi_rdata_i(m_axi_rdata_i)
      ,.axi_rresp_i(m_axi_rresp_i)
      ,.axi_rlast_i(m_axi_rlast_i)
      ,.axi_rvalid_i(m_axi_rvalid_i)
      ,.axi_rready_o(m_axi_rready_o)

      // Unused
      ,.axi_awaddr_cache_id_o()
      ,.axi_araddr_cache_id_o()
      );





//- ---------------- - - - - - - - - - --          --- ----             ---- ----             ---- ----             --



  ////                        ////
  ////      TIE OFF           ////
  ////                        ////


  // IO P tie off
  for (genvar i = 1; i < num_pods_x_p*num_tiles_x_p; i++) begin
    bsg_manycore_link_sif_tieoff #(
      .addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
    ) io_p_tieoff (
      .clk_i(clk_i)
      ,.reset_i(reset_r)
      ,.link_sif_i(io_link_sif_lo[i][P])
      ,.link_sif_o(io_link_sif_li[i][P])
    );
  end

  // IO west end tieoff
  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) io_w_tieoff (
    .clk_i(clk_i)
    ,.reset_i(reset_r)
    ,.link_sif_i(io_link_sif_lo[0][W])
    ,.link_sif_o(io_link_sif_li[0][W])
  );

  // IO east end tieoff
  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) io_e_tieoff (
    .clk_i(clk_i)
    ,.reset_i(reset_r)
    ,.link_sif_i(io_link_sif_lo[(num_pods_x_p*num_tiles_x_p)-1][E])
    ,.link_sif_o(io_link_sif_li[(num_pods_x_p*num_tiles_x_p)-1][E])
  );


  // SOUTH VER LINK TIE OFFS
  for (genvar i = 0; i < num_pods_x_p*num_tiles_x_p; i++) begin
    bsg_manycore_link_sif_tieoff #(
      .addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
    ) ver_s_tieoff (
      .clk_i(clk_i)
      ,.reset_i(reset_r)
      ,.link_sif_i(ver_link_sif_lo[S][i])
      ,.link_sif_o(ver_link_sif_li[S][i])
    );
  end


  // HOR TIEOFF (local link)
  for (genvar i = W; i <= E; i++) begin
    for (genvar j = 0; j < num_pods_y_p; j++) begin
      for (genvar k = 0; k < num_tiles_y_p; k++) begin
        bsg_manycore_link_sif_tieoff #(
          .addr_width_p(addr_width_p)
          ,.data_width_p(data_width_p)
          ,.x_cord_width_p(x_cord_width_p)
          ,.y_cord_width_p(y_cord_width_p)
        ) hor_tieoff (
          .clk_i(clk_i)
          ,.reset_i(reset_r)
          ,.link_sif_i(hor_link_sif_lo[i][j][k])
          ,.link_sif_o(hor_link_sif_li[i][j][k])
        );
      end
    end
  end


  // RUCHE LINK TIEOFF (west)
  for (genvar j = 0; j < num_pods_y_p; j++) begin
    for (genvar k = 0; k < num_tiles_y_p; k++) begin
      // hard coded for ruche factor 3
      assign ruche_link_li[W][j][k] = '0;
    end
  end

  // RUCHE LINK TIEOFF (east)
  for (genvar j = 0; j < num_pods_y_p; j++) begin
    for (genvar k = 0; k < num_tiles_y_p; k++) begin
      // hard coded for ruche factor 3
      assign ruche_link_li[E][j][k] = '0;
    end
  end
  








//                  //
//    PROFILERS     //
//                  //

// NOTE: Verilator does not allow parameter-controlled module binds
// (There's an issue filed, but not fixed as of 4.222). There are two ways we can fix this:
//
// 1. Clock gate the profilers based on the profiler parameter. E.g.:
//   ,.clk_i(clk_i && $root.`HOST_MODULE_PATH.testbench.enable_vcore_profiling_p)
//
// 2. Disable the profilers using Macros.
//
// Using clock gating was somewhat controversial, so for the moment we
// are controling the instantiation using macros *** FOR VERILATOR
// ONLY ***
//
// I agree that this is super annoying but until it gets fixed, this
// is the only way to prevent Verilator from running the profilers and
// slowing down simulation.

// Exponential parsing from surelog: https://github.com/chipsalliance/Surelog/issues/2035
`ifndef SURELOG
`ifndef VERILATOR_WORKAROUND_DISABLE_VCORE_PROFILING
if (enable_vcore_profiling_p) begin
  // vanilla core profiler
   bind vanilla_core vanilla_core_profiler #(
    .x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.icache_tag_width_p(icache_tag_width_p)
    ,.icache_entries_p(icache_entries_p)
    ,.data_width_p(data_width_p)
    ,.origin_x_cord_p(`BSG_MACHINE_ORIGIN_X_CORD)
    ,.origin_y_cord_p(`BSG_MACHINE_ORIGIN_Y_CORD)
  ) vcore_prof (
    .*
    ,.clk_i(clk_i)
    ,.global_ctr_i($root.`HOST_MODULE_PATH.global_ctr)
    ,.print_stat_v_i($root.`HOST_MODULE_PATH.print_stat_v)
    ,.print_stat_tag_i($root.`HOST_MODULE_PATH.print_stat_tag)
    ,.trace_en_i($root.`HOST_MODULE_PATH.trace_en)
  );
end
`endif

`ifndef VERILATOR_WORKAROUND_DISABLE_REMOTE_OP_PROFILING
if (enable_remote_op_profiling_p) begin
  bind network_tx remote_load_trace #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.pod_x_cord_width_p(pod_x_cord_width_p)
    ,.pod_y_cord_width_p(pod_y_cord_width_p)
    ,.num_tiles_x_p(num_tiles_x_p)
    ,.num_tiles_y_p(num_tiles_y_p)
    ,.origin_x_cord_p(`BSG_MACHINE_ORIGIN_X_CORD)
    ,.origin_y_cord_p(`BSG_MACHINE_ORIGIN_Y_CORD)
  ) rlt (
    .*
    ,.clk_i(clk_i)
    ,.global_ctr_i($root.`HOST_MODULE_PATH.global_ctr)
    ,.trace_en_i($root.`HOST_MODULE_PATH.trace_en)
  );
end
`endif

`ifndef VERILATOR_WORKAROUND_DISABLE_VCACHE_PROFILING
if (enable_cache_profiling_p) begin
  bind bsg_cache vcache_profiler #(
    .data_width_p(data_width_p)
    ,.addr_width_p(addr_width_p)
    ,.header_print_p({`BSG_STRINGIFY(`HOST_MODULE_PATH),".testbench.DUT.py[0].podrow.px[0].pod.north_vc_x[0].north_vc_row.vc_y[0].vc_x[0].vc.cache.vcache_prof"})
    ,.ways_p(ways_p)
  ) vcache_prof (
    // everything else
    .*
    ,.clk_i(clk_i)
    // bsg_cache_miss
    ,.chosen_way_n(miss.chosen_way_n)
    // from testbench
    ,.global_ctr_i($root.`HOST_MODULE_PATH.global_ctr)
    ,.print_stat_v_i($root.`HOST_MODULE_PATH.print_stat_v)
    ,.print_stat_tag_i($root.`HOST_MODULE_PATH.print_stat_tag)
    ,.trace_en_i($root.`HOST_MODULE_PATH.trace_en)
  );

  end
`endif

// Covergroups are not fully supported by Verilator 4.213
`ifndef VERILATOR
`ifndef VERILATOR_WORKAROUND_DISABLE_ROUTER_PROFILER
if (enable_router_profiling_p) begin
  bind bsg_mesh_router router_profiler #(
    .x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.dims_p(dims_p)
    ,.XY_order_p(XY_order_p)
    ,.origin_x_cord_p(`BSG_MACHINE_ORIGIN_X_CORD)
    ,.origin_y_cord_p(`BSG_MACHINE_ORIGIN_Y_CORD)
  ) rp0 (
    .*
    ,.clk_i(clk_i)
    ,.global_ctr_i($root.`HOST_MODULE_PATH.global_ctr)
    ,.trace_en_i($root.`HOST_MODULE_PATH.trace_en)
    ,.print_stat_v_i($root.`HOST_MODULE_PATH.print_stat_v)
  );
end
`endif

`ifndef VERILATOR_WORKAROUND_DISABLE_VCORE_COVERAGE
if (enable_vcore_pc_coverage_p) begin
  bind vanilla_core bsg_nonsynth_manycore_vanilla_core_pc_cov #(
    .icache_tag_width_p(icache_tag_width_p)
    ,.icache_entries_p(icache_entries_p)
  )
  pc_cov (
    .*
    ,.clk_i(clk_i)
    ,.coverage_en_i($root.`HOST_MODULE_PATH.coverage_en)
  );
end
`endif
`endif
`endif

  ///             ///
  ///   TRACER    ///
  ///             ///
  
`ifndef VERILATOR_WORKAROUND_DISABLE_VCORE_TRACE
if (enable_vanilla_core_trace_p) begin
  bind vanilla_core vanilla_core_trace #(
    .x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.icache_tag_width_p(icache_tag_width_p)
    ,.icache_entries_p(icache_entries_p)
    ,.data_width_p(data_width_p)
    ,.dmem_size_p(dmem_size_p)
  ) trace0 (
    .*
    ,.clk_i(clk_i)
  );
end
`endif

  //////////////////
  // PC Histogram //
  //////////////////
`ifndef VERILATOR_WORKAROUND_DISABLE_PC_HISTOGRAM
if (enable_vanilla_core_pc_histogram_p) begin
  bind vanilla_core vanilla_core_pc_histogram
    #(.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.data_width_p(data_width_p)
      ,.icache_tag_width_p(icache_tag_width_p)
      ,.icache_entries_p(icache_entries_p)
      ,.origin_x_cord_p(`BSG_MACHINE_ORIGIN_X_CORD)
      ,.origin_y_cord_p(`BSG_MACHINE_ORIGIN_Y_CORD)
      )
  vcore_pc_hist
    (.*);
end // if (enable_vanilla_core_pc_histogram_p)
`endif


endmodule

`BSG_ABSTRACT_MODULE(bsg_nonsynth_manycore_testbench)

