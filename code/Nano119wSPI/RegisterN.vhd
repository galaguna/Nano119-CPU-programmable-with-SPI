--==========================================================
-- Universidad Atonoma Metropolitana, Unidad Lerma
--==========================================================
-- RegisterN.vhd
-- Programador: Gerardo Laguna
-- 21 de octubre 2025
--==========================================================

--=============================
-- Registro de N bits
--=============================
library ieee;
use ieee.std_logic_1164.all;

entity RegisterN is
   generic(N: natural);
   port(
      clk: in std_logic;
      reset: in std_logic;
      d: in std_logic_vector(N-1 downto 0);
      q: out std_logic_vector(N-1 downto 0)
   );
end RegisterN;

architecture arch of RegisterN is
begin
   process(clk,reset)
   begin
      if (reset='1') then
         q <=(others=>'0');
      elsif (clk'event and clk='1') then
         q <= d;
      end if;
   end process;
end arch;
