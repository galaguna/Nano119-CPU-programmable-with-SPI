--=============================================================================
-- int_ctrl.vhd
--=============================================================================
-- Codigo para controlar interrupciones de CPU Nano
--=============================================================================
-- Author: Gerardo Laguna
-- Universidad Autonoma Metropolitana
-- Unidad Lerma
-- Fecha: 22/oct/2025
--=============================================================================
-------------------------------------------------------------------------------------
-- Library declarations
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------------
-- Entity declaration
-------------------------------------------------------------------------------------
entity int_ctrl is
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
end int_ctrl;

architecture arch of int_ctrl is
----------------------------------------------------------------------------------------------------
-- Components declaration
-------------------------------------------------------------------------------------------------

component RegisterN is
   generic(N: natural);
   port(
      clk,reset: in std_logic;
      d: in std_logic_vector(N-1 downto 0);
      q: out std_logic_vector(N-1 downto 0)
   );
end component;


----------------------------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------------------------
   signal cs0, cs1: std_logic;
   signal clk0, clk1: std_logic;
   signal En_reg: std_logic_vector(7 downto 0);
   signal Flg_reg: std_logic_vector(7 downto 0);
   signal int0_driv, int1_driv, int2_driv: std_logic;

----------------------------------------------------------------------------------------------------
-- Architecture body
----------------------------------------------------------------------------------------------------

begin

    Reg0 : RegisterN
     generic map(N => 8)  
     port map (
        clk => clk0,
        reset => rst,
		d => di,        
		q => En_reg
    );

    Reg1 : RegisterN
     generic map(N => 8)  
     port map (
        clk => clk1,
        reset => rst,
        d => di,
        q => Flg_reg
    );

   cs0 <= not add(0) and not add(1) and not add(2) and not add(3) and not add(4) and not add(5) and not add(6) and not add(7);
   
   cs1 <= add(0) and not add(1) and not add(2) and not add(3) and not add(4) and not add(5) and not add(6) and not add(7);

   clk0 <=  cs0 and we and clk;

   clk1 <=  cs1 and we and clk;

   int0_driv <= (eint0 and En_reg(0)) or Flg_reg(0); 
   int1_driv <= (eint1 and En_reg(1)) or Flg_reg(1); 
   int2_driv <= (eint2 and En_reg(2)) or Flg_reg(2); 

   --  outputs
   do <= En_reg when cs0 ='1' else 
   		 ("00000" & int2_driv & int1_driv & int0_driv) when cs1 ='1' else
   		 (others=>'Z');

   int0 <= int0_driv;
   int1 <= int1_driv;
   int2 <= int2_driv;

   ack0 <= Flg_reg(0);
   ack1 <= Flg_reg(1);
   ack2 <= Flg_reg(2);
 
end arch;