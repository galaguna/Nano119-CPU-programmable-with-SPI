--==========================================================
-- Universidad Atonoma Metropolitana, Unidad Lerma
--==========================================================
-- Counter16.vhd
-- Programador: Gerardo Laguna
-- 6 de junio 2025
--==========================================================
-- A partir de codigo 4.9 del libro 
-- Chu, Pong P. (2008). FPGA Prototyping by VHDL Examples. EUA: Wiley.
--!!!Gracias Prof. P. Chu :) !!! 
--==========================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity Bin_Counter16 is
   port(
      clk, reset: in std_logic;
      q: out std_logic_vector(15 downto 0)
   );
end Bin_Counter16;

architecture arch of Bin_Counter16 is
   signal r_reg: unsigned(15 downto 0);
   signal r_next: unsigned(15 downto 0);
begin
   -- register
   process(clk,reset)
   begin
      if (reset='1') then
         r_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         r_reg <= r_next;
      end if;
   end process;
   -- next-state logic
   r_next <= r_reg + 1;
   -- output logic
   q <= std_logic_vector(r_reg);
end arch;