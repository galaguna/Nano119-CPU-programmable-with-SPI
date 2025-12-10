--=============================================================================
-- Entidad Nano_mcsys_cnfg con CPU Nano, memoria, comunicacion SPI y
-- bloques perifericos para operar con interrupciones.
-- * Se puede configurar tanto la velocidad del reloj del CPU 
--   como la de la senial SCK del modulo SPI.
--=============================================================================
-- Codigo beta 
--=============================================================================
-- Author: Gerardo A. Laguna S.
-- Universidad Autonoma Metropolitana
-- Unidad Lerma
-- 6.nov.2025
-------------------------------------------------------------------------------
-- Library declarations
-------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- Entity declaration
-------------------------------------------------------------------------------
entity Nano_mcsys_cnfg is
    generic (CPU_CLK_SEL: natural; SPI_CLK_SEL: natural);
port (
  CLK          : in std_logic;
  RST          : in std_logic; 
  RUN          : in std_logic;  
  MODE         : in std_logic;
  STATE        : out std_logic_vector(7 downto 0);
  FLAGS        : out std_logic_vector(7 downto 0);
  R_REG        : out std_logic_vector(31 downto 0);
  EINT0,EINT1,EINT2 : in std_logic;
  SPI_CS       : in std_logic;
  SPI_MOSI     : in std_logic;
  SPI_MISO     : out std_logic;
  SPI_SCK      : in std_logic   
);
end Nano_mcsys_cnfg;

architecture my_arch of Nano_mcsys_cnfg is

-------------------------------------------------------------------------------
-- Components declaration
-------------------------------------------------------------------------------

component edge_detector is
   port(
      clk   : in std_logic;
      rst   : in std_logic;
      x     : in std_logic;
      clr   : in std_logic;
      y     : out std_logic
   );
end component;

component deboucing_3tics is
   port(
      clk   : in std_logic;
      rst   : in std_logic;
      x     : in std_logic;
      y     : out std_logic
   );
end component;

component pulse_generator is
   port(
      clk, reset  : in std_logic;
      trigger     : in std_logic;
      p           : out std_logic
   );
end component;

component Bin_CounterN is
   generic(N: natural);
   port(
      clk, reset: in std_logic;
      q: out std_logic_vector(N-1 downto 0)
   );
end component;

component sync_ram is
 generic(DATA_WIDTH: natural; ADD_WIDTH: natural);
 port (
    clock   : in  std_logic;
    we      : in  std_logic;
    address : in  std_logic_vector;
    datain  : in  std_logic_vector;
    dataout : out std_logic_vector
  );
end component;

component  Nano_cpu is
  port(
     clk, reset : in std_logic;
     run        : in std_logic;
     state      : out std_logic_vector(7 downto 0);
     flags      : out std_logic_vector(7 downto 0);
     code_add   : out std_logic_vector(11 downto 0);
     code       : in std_logic_vector(7 downto 0);
     data_add   : out std_logic_vector(10 downto 0);
     din        : in std_logic_vector(15 downto 0);
     dout       : out std_logic_vector(15 downto 0);
     data_we    : out std_logic;
     stk_add    : out std_logic_vector(7 downto 0);
     sin        : in std_logic_vector(15 downto 0);
     sout       : out std_logic_vector(15 downto 0);
     stk_we     : out std_logic;
     io_add     : out std_logic_vector(7 downto 0);
     io_i       : in std_logic_vector(7 downto 0);
     io_o       : out std_logic_vector(7 downto 0);
     io_we      : out std_logic;
     int0,int1,int2 : in std_logic;
     r_out      : out std_logic_vector(31 downto 0)
 );
end component;

component nano_spictrl is
    generic (CLK_DIVISOR: natural);
   port(
      CLK, RST: in std_logic;
      CS, MOSI, SCK: in std_logic;
      MISO: out std_logic;
      CIN: in std_logic_vector(7 downto 0);
      COUT: out std_logic_vector(7 downto 0);
      CADD: out std_logic_vector(11 downto 0);
      CWE: out std_logic;
      DIN: in std_logic_vector(15 downto 0);
      DOUT: out std_logic_vector(15 downto 0);
      DADD: out std_logic_vector(10 downto 0);
      DWE: out std_logic;
      PCLK: out std_logic
  );
end component;

component int_ctrl is
   port(
      clk,rst: in  std_logic;
      add: in std_logic_vector(7 downto 0);
      di: in std_logic_vector(7 downto 0);
      do: out std_logic_vector(7 downto 0);
      we: in  std_logic;
      eint0,eint1,eint2: in  std_logic;
      ack0,ack1,ack2: out std_logic;
      int0,int1,int2: out std_logic
   );
end component;

-------------------------------------------------------------------------------
-- Signal declaration
-------------------------------------------------------------------------------
signal clk_sel       : std_logic_vector(3 downto 0);
signal div_clk       : std_logic_vector(27 downto 0);
signal nano_clk      : std_logic;
signal mem_clk       : std_logic;

signal cpu2ram_dout  : std_logic_vector(15 downto 0);
signal spi2ram_dout  : std_logic_vector(15 downto 0);

signal cpu2ram_din   : std_logic_vector(15 downto 0);
signal mxd_ram_din   : std_logic_vector(15 downto 0);
signal spi2ram_din   : std_logic_vector(15 downto 0);

signal cpu2ram_add   : std_logic_vector(10 downto 0);
signal mxd_ram_add   : std_logic_vector(10 downto 0);
signal spi2ram_add   : std_logic_vector(10 downto 0);

signal cpu2ram_we    : std_logic;
signal mxd_ram_we    : std_logic;
signal spi2ram_we    : std_logic;

signal cpu2rom_dout  : std_logic_vector(7 downto 0);
signal spi2rom_dout  : std_logic_vector(7 downto 0);

signal mxd_rom_din   : std_logic_vector(7 downto 0);
signal spi2rom_din   : std_logic_vector(7 downto 0);

signal cpu2rom_add   : std_logic_vector(11 downto 0);
signal mxd_rom_add   : std_logic_vector(11 downto 0);
signal spi2rom_add   : std_logic_vector(11 downto 0);

signal mxd_rom_we    : std_logic;
signal spi2rom_we    : std_logic;

signal cpu2stk_dout  : std_logic_vector(15 downto 0);
signal cpu2stk_din   : std_logic_vector(15 downto 0);
signal cpu2stk_add   : std_logic_vector(7 downto 0);
signal cpu2stk_we    : std_logic;

signal cpu2intctrl_dout  : std_logic_vector(7 downto 0);
signal cpu2intctrl_din   : std_logic_vector(7 downto 0);
signal cpu2intctrl_add   : std_logic_vector(7 downto 0);
signal cpu2intctrl_we    : std_logic;
signal cpu2intctrl_int0  : std_logic;
signal cpu2intctrl_int1  : std_logic;
signal cpu2intctrl_int2  : std_logic;

signal mxd_mem_clk   : std_logic;
signal prog_clk      : std_logic;

signal btnR_cln      : std_logic;
signal run_sig       : std_logic;

signal edge0_wire    : std_logic;
signal edge1_wire    : std_logic;
signal edge2_wire    : std_logic;
signal ack0_wire     : std_logic;
signal ack1_wire     : std_logic;
signal ack2_wire     : std_logic;

-------------------------------------------------------------------------------
-- Begin
-------------------------------------------------------------------------------
begin

  my_Counter : Bin_CounterN
    generic map(N => 28)  
    port map (
      clk => CLK,
      reset => RST,
      q => div_clk
    );
  
   my_deboucing : deboucing_3tics 
   port map(
      clk => nano_clk,
      rst => RST,
      x => RUN,
      y => btnR_cln
   );


my_pulse : pulse_generator 
   port map(
      clk  => nano_clk, 
      reset => RST,
      trigger => btnR_cln,
      p => run_sig
   );

my_Nano_Machine : Nano_cpu
   port map(
      clk => nano_clk, 
      reset => RST,
      run  => run_sig,
      state => STATE,
      flags => FLAGS,
      code_add => cpu2rom_add,
      code => cpu2rom_dout,
      data_add => cpu2ram_add,
      din => cpu2ram_dout,
      dout => cpu2ram_din,
      data_we => cpu2ram_we,
      stk_add => cpu2stk_add,
      sin => cpu2stk_dout,
      sout => cpu2stk_din,
      stk_we => cpu2stk_we,
      io_add => cpu2intctrl_add,
      io_i => cpu2intctrl_dout,
      io_o => cpu2intctrl_din,
      io_we => cpu2intctrl_we,
      int0 => cpu2intctrl_int0,
      int1 => cpu2intctrl_int1,
      int2 => cpu2intctrl_int2,
      r_out => R_REG
  );

  mySpiCtrl : nano_spictrl
    generic map(CLK_DIVISOR => SPI_CLK_SEL)  
    port map (
        CLK => CLK, 
        RST => RST,
        CS => SPI_CS, 
        MOSI => SPI_MOSI, 
        SCK => SPI_SCK,
        MISO => SPI_MISO,
        CIN => spi2rom_dout,
        COUT => spi2rom_din,
        CADD => spi2rom_add,
        CWE => spi2rom_we,
        DIN => spi2ram_dout,
        DOUT => spi2ram_din,
        DADD => spi2ram_add,
        DWE => spi2ram_we,
        PCLK => prog_clk
  );

  my_RAM : sync_ram
    generic map(DATA_WIDTH => 16, 
    ADD_WIDTH => 11)
    port map (
        clock   => mxd_mem_clk,
        we      => mxd_ram_we,
        address => mxd_ram_add,
        datain  => mxd_ram_din,
        dataout => cpu2ram_dout
    );

  my_ROM : sync_ram
    generic map(DATA_WIDTH => 8, 
    ADD_WIDTH => 12)
    port map (
        clock   => mxd_mem_clk,
        we      => mxd_rom_we,
        address => mxd_rom_add,
        datain  => mxd_rom_din,
        dataout => cpu2rom_dout
    );

  my_STACK : sync_ram
    generic map(DATA_WIDTH => 16, 
    ADD_WIDTH => 8)
    port map (
        clock   => mem_clk,
        we      => cpu2stk_we,
        address => cpu2stk_add,
        datain  => cpu2stk_din,
        dataout => cpu2stk_dout
    );

  my_intctrl : int_ctrl
    port map(
      clk => mem_clk,
      rst => RST,
      add => cpu2intctrl_add,
      di => cpu2intctrl_din,
      do => cpu2intctrl_dout,
      we => cpu2intctrl_we,
      eint0 => edge0_wire,
      eint1 => edge1_wire,
      eint2 => edge2_wire,
      ack0 => ack0_wire,
      ack1 => ack1_wire,
      ack2 => ack2_wire,
      int0 => cpu2intctrl_int0,
      int1 => cpu2intctrl_int1,
      int2 => cpu2intctrl_int2
    );

  my_edge_det0 : edge_detector
   port map(
      clk => CLK,
      rst => RST,
      x => EINT0,
      clr => ack0_wire,
      y  => edge0_wire
   );

  my_edge_det1 : edge_detector
   port map(
      clk => CLK,
      rst => RST,
      x => EINT1,
      clr => ack1_wire,
      y  => edge1_wire
   );

  my_edge_det2 : edge_detector
   port map(
      clk => CLK,
      rst => RST,
      x => EINT2,
      clr => ack2_wire,
      y  => edge2_wire
   );

-- RAM's multiplexed control:
  mxd_ram_din <= cpu2ram_din when (MODE = '1') else
                  spi2ram_din;

  mxd_ram_add <= cpu2ram_add when (MODE = '1') else
                  spi2ram_add;

  mxd_ram_we <= cpu2ram_we when (MODE = '1') else 
                  spi2ram_we;

  mxd_rom_din <= (others => '0') when (MODE = '1') else
                  spi2rom_din;

  mxd_rom_add <= cpu2rom_add when (MODE = '1') else
                  spi2rom_add;

  mxd_rom_we <= '0' when (MODE = '1') else 
                  spi2rom_we;

  mxd_mem_clk <= mem_clk when (MODE = '1') else 
                  prog_clk;

-- Conections:
  mem_clk <= not nano_clk;
    
  spi2ram_dout <= cpu2ram_dout;
  spi2rom_dout <= cpu2rom_dout;

  clk_sel <= std_logic_vector(to_unsigned(CPU_CLK_SEL, clk_sel'length));
    
  with clk_sel select
   nano_clk  <=  div_clk(12) when x"0",  
                div_clk(13) when x"1",
                div_clk(14) when x"2",
                div_clk(15) when x"3",
                div_clk(16) when x"4",
                div_clk(17) when x"5",
                div_clk(18) when x"6",
                div_clk(19) when x"7",
                div_clk(20) when x"8",
                div_clk(21) when x"9",
                div_clk(22) when x"A",
                div_clk(23) when x"B",
                div_clk(24) when x"C",
                div_clk(25) when x"D",
                div_clk(26) when x"E",
                div_clk(27) when x"F";


end my_arch;
