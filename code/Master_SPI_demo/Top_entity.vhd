
--=============================================================================
-- Proyecto de prueba para modulos de comunicación SPI con una tarjeta Basys3
--=============================================================================
--
-- El hardware sintetizado fue probado con el reloj del sistema 
-- de 100MHz y funciono bien, tanto el modulo maestro como el esclavo.
-- Se emplea la entidad master_spictrl que incluye un divisor de frecuencia 
-- para el reloj del sistema:
--  *El parametro CLK_DIVISOR es un valor entero en [0 : 15]
--   - Con CLK_DIVISOR=0 se obtiene una frecuencia en SCK de 6.25 MHz
--   - Con CLK_DIVISOR=15 se obtiene una frecuencia en SCK de 190.7 Hz
--
--=============================================================================
-- Codigo para probar el componente master_spictrl
-- con deboucing en boton de disparo.
--=============================================================================
-- Author: Gerardo Laguna
-- UAM lerma
-- Mexico
-- 11/06/2025
--=============================================================================
-------------------------------------------------------------------------------------
-- Library declarations
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------------
-- Entity declaration
-------------------------------------------------------------------------------------
entity my_basys is
   port(
    --Basys Resources
    sysclk        : in std_logic;
    btnC          : in std_logic; -- sys_rst 
    btnU          : in std_logic; -- Selector
    btnR          : in std_logic; -- Go
    led           : out std_logic_vector(15 downto 0);
    sw            : in std_logic_vector(15 downto 0);
    dp            : out  std_logic;
    an            : out  STD_LOGIC_VECTOR (3 downto 0);
    MST_CS        : out std_logic;
    MST_MOSI      : out std_logic;
    MST_MISO      : in std_logic;
    MST_SCK       : out std_logic   
    );
end my_basys;

architecture tst_arch of my_basys is
----------------------------------------------------------------------------------------------------
-- Components declaration
----------------------------------------------------------------------------------------------------

component deboucing_3tics is
   port(
      clk   : in std_logic;
      rst   : in std_logic;
      x     : in std_logic;
      y     : out std_logic
   );
end component;

component master_spictrl is
    generic (WORD_SIZE: natural;
            CLK_DIVISOR: natural);
   port(
      CLK, RST: in std_logic;
      CS, MOSI, SCK: out std_logic;
      MISO: in std_logic;
      TX_W: in std_logic_vector(WORD_SIZE-1 downto 0);
      RX_W: out std_logic_vector(WORD_SIZE-1 downto 0);
      GO: in std_logic;
      BUSY: out std_logic
  );
end component;

----------------------------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------------------------
signal tst_clk       : std_logic;
signal sys_rst       : std_logic;
signal usrclk        : std_logic_vector(27 downto 0); -- Senales para timing  
signal Tx_bus        : std_logic_vector(31 downto 0);   
signal Rx_bus        : std_logic_vector(31 downto 0); 
signal Working       : std_logic;
signal clr_input     : std_logic;
signal one_pulse     : std_logic;

----------------------------------------------------------------------------------------------------
-- Architecture body
----------------------------------------------------------------------------------------------------

begin

my_deboucing: deboucing_3tics
       port map(
          clk => sysclk,
          rst => sys_rst,
          x => btnR,
          y => clr_input
       );
    
    
U01 : master_spictrl
  generic map(WORD_SIZE => 32,
              CLK_DIVISOR => 0)  
  PORT MAP (
    CLK => sysclk, 
    RST => sys_rst,
    CS => MST_CS, 
    MOSI => MST_MOSI, 
    SCK => MST_SCK,
    MISO => MST_MISO,
    TX_W => Tx_bus,
    RX_W => Rx_bus,
    GO => clr_input,
    BUSY => Working
  );

    an <= "0111";
    dp <= not Working;
    sys_rst <= btnC;
    

    led <=  Rx_bus(15 downto 0) when btnU='0' else
            Rx_bus(31 downto 16);

    Tx_bus <= x"A500" & sw;
    
end tst_arch;