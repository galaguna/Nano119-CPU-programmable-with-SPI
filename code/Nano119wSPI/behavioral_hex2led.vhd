--=============================================================================
-- Entidad para despliegue de caracterese hexadecimales
--=============================================================================
-- Codigo para la monografia:
-- La Maquina de Post actualizada:
-- Diseno, puesta en marcha y programacion del 
-- prototipo de un pequeno CPU funcional
--=============================================================================
-- Author: Gerardo A. Laguna S.
-- Universidad Autonoma Metropolitana
-- Unidad Lerma
-- 26.marzo.2020
--------------------------------------------------------------------------------
-- Library declarations
--------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--------------------------------------------------------------------------------
-- Entity declaration
--------------------------------------------------------------------------------

entity hex2led is
    Port ( 
            HEX : in  std_logic_vector(3 downto 0);
			   LED : out std_logic_vector(6 downto 0 )
         );
end hex2led;

architecture behavioral_arch of hex2led is
-------------------------------------------------------------------------------- 
-- Components declaration
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Signal declaration
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Architecture body
--------------------------------------------------------------------------------

begin

-- 
-- segment encoding
--      0
--     ---  
--  5 |   | 1
--     ---   <- 6
--  4 |   | 2
--     ---
--      3

   with HEX SELect
   LED<= "1111001" when "0001",   --1
         "0100100" when "0010",   --2
         "0110000" when "0011",   --3
         "0011001" when "0100",   --4
         "0010010" when "0101",   --5
         "0000010" when "0110",   --6
         "1111000" when "0111",   --7
         "0000000" when "1000",   --8
         "0010000" when "1001",   --9
         "0001000" when "1010",   --A
         "0000011" when "1011",   --b
         "1000110" when "1100",   --C
         "0100001" when "1101",   --d
         "0000110" when "1110",   --E
         "0001110" when "1111",   --F
         "1000000" when others;   --0

end behavioral_arch; 
