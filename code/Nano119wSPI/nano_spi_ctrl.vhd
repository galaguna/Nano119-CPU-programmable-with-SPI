
--=============================
-- nano_spi_ctrl.vhd
--=============================
--=============================================================================
-- Author: Gerardo Laguna
-- UAM lerma
-- Mexico
-- 27/06/2025
--=============================================================================
-- *Esta version emplea el contador generico Bin_CounterN
-------------------------------------------------------------------------------------
-- Library declarations
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------------
-- Entity declaration
-------------------------------------------------------------------------------------
entity nano_spictrl is
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
end nano_spictrl;

architecture arch of nano_spictrl is
----------------------------------------------------------------------------------------------------
-- Components declaration
----------------------------------------------------------------------------------------------------
component Bin_CounterN is
   generic(N: natural);
   port(
      clk, reset: in std_logic;
      q: out std_logic_vector(N-1 downto 0)
   );
end component;

component slave_spi4nano is
   port(
      CLK, RST: in std_logic;
      CS, MOSI, SCK: in std_logic;
      MISO: out std_logic;
      cin_prg: in std_logic_vector(7 downto 0);
      cout_prg: out std_logic_vector(7 downto 0);
      cadd_prg: out std_logic_vector(11 downto 0);
      cwe_prg: out std_logic;
      din_prg: in std_logic_vector(15 downto 0);
      dout_prg: out std_logic_vector(15 downto 0);
      dadd_prg: out std_logic_vector(10 downto 0);
      dwe_prg: out std_logic;
      prog_clk: out std_logic
  );
end component;

----------------------------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------------------------
signal clk_sel       : std_logic_vector(3 downto 0);
signal div_clk       : std_logic_vector(15 downto 0);
signal loc_clk       : std_logic;

----------------------------------------------------------------------------------------------------
-- Architecture body
----------------------------------------------------------------------------------------------------

begin

my_Counter : Bin_CounterN
  generic map(N => 16)  
  port map (
    clk => CLK,
    reset => RST,
    q => div_clk
  );
  
    
my_nano_spi : slave_spi4nano
  port map (
      CLK => loc_clk,
      RST => RST,
      CS => CS,
      MOSI => MOSI,
      SCK => SCK,
      MISO => MISO,
      cin_prg => CIN,
      cout_prg => COUT,
      cadd_prg => CADD,
      cwe_prg => CWE,
      din_prg => DIN,
      dout_prg => DOUT,
      dadd_prg => DADD,
      dwe_prg => DWE,
      prog_clk => PCLK
  );

  clk_sel <= std_logic_vector(to_unsigned(CLK_DIVISOR, clk_sel'length));
    
  with clk_sel select
   loc_clk  <=  div_clk(0) when x"0",  
                div_clk(1) when x"1",
                div_clk(2) when x"2",
                div_clk(3) when x"3",
                div_clk(4) when x"4",
                div_clk(5) when x"5",
                div_clk(6) when x"6",
                div_clk(7) when x"7",
                div_clk(8) when x"8",
                div_clk(9) when x"9",
                div_clk(10) when x"A",
                div_clk(11) when x"B",
                div_clk(12) when x"C",
                div_clk(13) when x"D",
                div_clk(14) when x"E",
                div_clk(15) when x"F";
    
end arch;