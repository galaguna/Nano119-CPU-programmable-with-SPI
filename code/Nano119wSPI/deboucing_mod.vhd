--=============================================================================
-- Entidad para eliminacion de rebotes en senales de entrada
--=============================================================================
-- Codigo para la monografia:
-- La Maquina de Post actualizada:
-- Diseno, puesta en marcha y programacion del 
-- prototipo de un pequeno CPU funcional
--=============================================================================
-- Author: Gerardo A. Laguna S.
-- Universidad Autonoma Metropolitana
-- Unidad Lerma
-- 2.junio.2025
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deboucing_3tics is
   port(
      clk   : in std_logic;
      rst   : in std_logic;
      x     : in std_logic;
      y     : out std_logic
   );
end deboucing_3tics;

architecture asmd_arch of deboucing_3tics is
   constant N_TICS: natural:= 3;
   type asmd_state_type is (Low, Idle, High);
   signal state_reg, state_next: asmd_state_type;
   signal c_reg, c_next: unsigned(3 downto 0);

begin
   -- state and data registers
   process(clk,rst)
   begin
      if (rst='1') then
         state_reg <= Low;
         c_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
         c_reg <= c_next;
      end if;
   end process;

   -- next-state logic & data path functional units/routing
   process(state_reg,x,c_reg)
   begin
      y <= '0';
      c_next <= c_reg;
      case state_reg is
         when Low =>
            if x='1' then
               state_next <= Idle;
            else
               state_next <= Low;
            end if;
            c_next <= (others=>'0');
         when Idle =>
            if x='1' then
               if (c_reg=N_TICS-1) then
                  state_next <=High;
               else
                  state_next <=Idle;
                  c_next <= c_reg + 1;
               end if;
            else
               state_next <=Low;
            end if;
         when High =>
            if x='1' then
               state_next <= High;
            else
               state_next <= Low;
            end if;
            y <= '1';
      end case;
   end process;
end asmd_arch;


