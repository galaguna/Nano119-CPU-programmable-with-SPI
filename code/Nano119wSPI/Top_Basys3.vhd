--=============================================================================
-- Entidad integradora para el sistema de procesamiento con CPU Nano en una tarjeta Basys3
-- *Incluye bloques perifericos para operar con interrupciones.
-- *Incluye comunicacion SPI para la escritura/lectura
--  de los espacios de programa y datos.
--=============================================================================
-- Codigo beta que emplea el reloj de 100 MHz de la tarjeta Basys:
--      * El reloj del CPU se configura en el orden de las decimas de segundo 
--        (.CPU_CLK_SEL(10) en modulo Nano_mcsys_cnfg)
--      * La velocidad para la comunicacion SPI se configura para producir una 
--        senial SCK=191 Hz (en realidad, 190.8 Hz)
--        (.SPI_CLK_SEL(15) en modulo Nano_mcsys_cnfg)  
--=============================================================================
-- Author: Gerardo A. Laguna S.
-- Universidad Autonoma Metropolitana
-- Unidad Lerma
-- 6.noviembre.2025
-------------------------------------------------------------------------------
-- Library declarations
-------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- Entity declaration
-------------------------------------------------------------------------------
entity Basys3_system is
port (

  --Basys3 Resources
  btnC          : in std_logic; -- sys_rst 
  btnR          : in std_logic; -- run_sig 
  sysclk        : in std_logic;
  led           : out std_logic_vector(15 downto 0);
  sw            : in std_logic_vector(15 downto 0);
  seg           : out std_logic_vector(6 downto 0);
  an            : out std_logic_vector(3 downto 0);
  SLV_CS        : in std_logic;
  SLV_MOSI      : in std_logic;
  SLV_MISO      : out std_logic;
  SLV_SCK       : in std_logic   

);
end Basys3_system;

architecture my_arch of Basys3_system is

-------------------------------------------------------------------------------
-- Components declaration
-------------------------------------------------------------------------------

component Bin_CounterN is
   generic(N: natural);
   port(
      clk, reset: in std_logic;
      q: out std_logic_vector(N-1 downto 0)
   );
end component;

component hex2led
    port ( 
      hex   : in std_logic_vector(3 downto 0);
      led   : out std_logic_vector(6 downto 0 )
  );
end component;

component Nano_mcsys_cnfg is
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
end component;

-------------------------------------------------------------------------------
-- Signal declaration
-------------------------------------------------------------------------------
signal sys_rst       : std_logic;
signal run_sig       : std_logic;
signal op_mode       : std_logic;
signal usrclk        : std_logic_vector(15 downto 0); -- Senales para timing  
signal disp_driver   : std_logic_vector(6 downto 0); -- Disp. 7 segmentos LED  
signal disp_nible    : std_logic_vector(3 downto 0);

signal state_byte    : std_logic_vector(7 downto 0);
signal flags_byte    : std_logic_vector(7 downto 0);
signal result_word   : std_logic_vector(31 downto 0);

Alias display_cnt    : std_logic_vector is usrclk(15 downto 14);


-------------------------------------------------------------------------------
-- Begin
-------------------------------------------------------------------------------
begin

    myNanoSys: Nano_mcsys_cnfg
    generic map(CPU_CLK_SEL => 10, SPI_CLK_SEL=>15)  
    port map (
        CLK => sysclk,
        RST => sys_rst, 
        RUN => run_sig,  
        MODE => op_mode,
        STATE => state_byte,
        FLAGS => flags_byte,
        R_REG => result_word,
        EINT0 => sw(8),
        EINT1 => sw(9),
        EINT2 => sw(10),
        SPI_CS => SLV_CS,
        SPI_MOSI => SLV_MOSI,
        SPI_MISO => SLV_MISO,
        SPI_SCK => SLV_SCK   
    );


    my_Counter : Bin_CounterN
     generic map(N => 16)  
     port map (
        clk => sysclk,
        reset => sys_rst,
        q => usrclk
    );
  
 -- Binary coded Hexa to 7 segments display:

    my_Display7seg : hex2led 
    port map (
          hex => disp_nible,
          led => disp_driver 
      );
             
-- Display logic:

    with display_cnt select
      disp_nible<=  state_byte(7 downto 4) when "00",   --Disp 0
                    state_byte(3 downto 0) when "01",   --Disp 1
                    flags_byte(7 downto 4) when "10",   --Disp 2
                    flags_byte(3 downto 0) when "11";   --Disp 3


    with display_cnt select
      an<= "0111" when "00",   --Disp 0
           "1011" when "01",   --Disp 1
           "1101" when "10",   --Disp 2
           "1110" when "11";   --Disp 3

    seg <= disp_driver;


-- Conections:
    sys_rst <= btnC;
    run_sig <= btnR;
    op_mode <= sw(15);
    
    led <=  result_word(15 downto 0) when sw(0)='0' else
            result_word(31 downto 16);
end my_arch;
