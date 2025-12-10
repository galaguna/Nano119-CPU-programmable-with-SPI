--=============================================================================
-- Entidad para generar un pulso
--=============================================================================
-- Codigo para realizacion de pruebas manuales con botones
--=============================================================================
-- Author: Gerardo A. Laguna S.
-- Universidad Autonoma Metropolitana
-- Unidad Lerma
-- 28.mayo.2025
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity pulse_generator is
   port(
      clk, reset  : in std_logic;
      trigger     : in std_logic;
      p           : out std_logic
   );
end pulse_generator;

architecture moore_arch of pulse_generator is

   type state_type is (idle, High, wait_low);
   signal state_reg, state_next: state_type;

begin
   -- state register
   process(clk,reset)
   begin
      if (reset='1') then
         state_reg <= idle;
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
      end if;
   end process;
   -- next-state and output logic
   process(state_reg,trigger)
   begin
      p <= '0'; --By default
      case state_reg is
         when idle =>
            if trigger= '1' then
               state_next <= High;
            else
               state_next <= idle;
            end if;
         when High =>
            state_next <= wait_low;
            p <= '1'; --Moore Output
         when wait_low =>
            if trigger= '1' then
               state_next <= wait_low;
            else
               state_next <= idle;
            end if;
      end case;
   end process;
   
end moore_arch;

