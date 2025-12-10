--=============================================================================
-- Entidad para deteccion de flancos ascendentes
--=============================================================================
-- Bloque generico
--=============================================================================
-- Author: Gerardo A. Laguna S.
-- Universidad Autonoma Metropolitana
-- Unidad Lerma
-- 31.oct.2025
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity edge_detector is
   port(
      clk   : in std_logic;
      rst   : in std_logic;
      x     : in std_logic;
      clr   : in std_logic;
      y     : out std_logic
   );
end edge_detector;

architecture arch of edge_detector is
   type state_type is (idle, edge_detected);
   signal state_reg, state_next: state_type;

begin
   -- state and data registers
   process(clk,rst)
   begin
      if (rst='1') then
         state_reg <= idle;
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
      end if;
   end process;

   -- next-state logic 
   process(state_reg,x,clr)
   begin
      y <= '0';
      
      case state_reg is
         when idle =>
            if x='1' then
               state_next <= edge_detected;
            else
               state_next <= idle;
            end if;
         when edge_detected =>
            if clr='1' then
               state_next <= idle;
            else
               state_next <= edge_detected;
            end if;
            y <= '1';
      end case;
   end process;
end arch;


