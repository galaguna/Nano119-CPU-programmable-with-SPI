--=============================
-- nano_spi.vhd
--=============================
--
-- El hardware sintetizado fue probado con el reloj del sistema 
-- de 100MHz y funciono bien.
-- La velocidad maxima generada para la senal SCK fue de 12.5 MHz, alimentando
-- las senales de reloj con el reloj del sistema, sin division de frecuencia. 
-- La expresion para calcular la velocidad de SCK es la siguiente:
-- f_sck= clk/8
--
--=============================================================================
-- *Codigo para el componente slave_spi4nano*
--=============================================================================
-- Author: Gerardo Laguna
-- UAM lerma
-- Mexico
-- 19/09/2025
--=============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity slave_spi4nano is
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
end slave_spi4nano;

architecture arch of slave_spi4nano is
   type state_type is
      (idle1, wait_low_i, wait_high_i, do, 
      ini_read_rom, read_rom_clk, read_rom,
      ini_read_ram, read_ram_clk, read_ram,
      ini_write_rom, write_rom_clk, write_rom,
      ini_write_ram, write_ram_clk, write_ram,     
      end1, end2, idle2, wait_low_o, wait_high_o);

   signal state_reg, state_next: state_type;
   signal SRi_reg, SRi_next: std_logic_vector(31 downto 0);
   signal SRo_reg, SRo_next: std_logic_vector(31 downto 0);
   signal Cnt_reg, Cnt_next: unsigned(5 downto 0);
   signal MISO_buf_reg, MISO_buf_next: std_logic;
   signal cadd_buf_reg, cadd_buf_next: std_logic_vector(11 downto 0);
   signal cout_buf_reg, cout_buf_next: std_logic_vector(7 downto 0);
   signal dadd_buf_reg, dadd_buf_next: std_logic_vector(10 downto 0);
   signal dout_buf_reg, dout_buf_next: std_logic_vector(15 downto 0);

   signal cwe_buf_reg, cwe_buf_next     :  std_logic;
   signal dwe_buf_reg, dwe_buf_next     :  std_logic;
   signal pclk_buf_reg, pclk_buf_next   :  std_logic;

   Alias  Read_bit : std_logic is SRi_reg(31);
   Alias  Add_reg : std_logic_vector(14 downto 0) is SRi_reg(30 downto 16);
   Alias  Data_reg : std_logic_vector(15 downto 0) is SRi_reg(15 downto 0);

begin
   -- state & data registers
   process(CLK,RST)
   begin
      if (RST='1') then
         state_reg <= idle1;
         SRi_reg <= (others=>'0');
         SRo_reg <= (others=>'0');
         Cnt_reg <= (others=>'0');
         MISO_buf_reg <= '0';
         cadd_buf_reg <= (others=>'0');
         cout_buf_reg <= (others=>'0');
         dadd_buf_reg <= (others=>'0');
         dout_buf_reg <= (others=>'0');
         cwe_buf_reg <= '0';
         dwe_buf_reg <= '0';
         pclk_buf_reg <= '0';
      elsif (CLK'event and CLK='1') then
         state_reg <= state_next;
         SRi_reg <= SRi_next;
         SRo_reg <= SRo_next;
         Cnt_reg <= Cnt_next;
         MISO_buf_reg <= MISO_buf_next; 
         cadd_buf_reg <= cadd_buf_next;
         cout_buf_reg <= cout_buf_next;
         dadd_buf_reg <= dadd_buf_next;
         dout_buf_reg <= dout_buf_next;
         cwe_buf_reg <= cwe_buf_next;
         dwe_buf_reg <= dwe_buf_next;
         pclk_buf_reg <= pclk_buf_next;
      end if;
   end process;
   
   -- next-state logic & data path functional units/routing
   process(state_reg,CS,MOSI,SCK,cin_prg,din_prg,
           SRi_reg,SRo_reg,Cnt_reg,
           MISO_buf_reg,cadd_buf_reg,cout_buf_reg,dadd_buf_reg,dout_buf_reg)
   begin
      SRi_next <= SRi_reg;
      SRo_next <= SRo_reg;
      Cnt_next <= Cnt_reg;
      MISO_buf_next <= MISO_buf_reg;
      cadd_buf_next <= cadd_buf_reg;
      cout_buf_next <= cout_buf_reg;
      dadd_buf_next <= dadd_buf_reg;
      dout_buf_next <= dout_buf_reg;

      case state_reg is
         when idle1 =>
            if CS='0' then
               state_next <= wait_low_i;
            else
               state_next <= idle1;
            end if;
            SRi_next <= (others=>'0');
            Cnt_next <= (others=>'0');
         when wait_low_i =>
            if CS='0' then
               if SCK='0' then
                  MISO_buf_next <= SRo_reg(31); 
                  SRo_next <= SRo_reg(30 downto 0) & '0';
                  state_next <= wait_high_i;                  
               else
                  state_next <= wait_low_i;
               end if;
            else
               state_next <= idle1;
            end if;

         when wait_high_i =>
            if CS='0' then
               if SCK='1' then
                  SRi_next <= SRi_reg(30 downto 0) & MOSI;
                  
                  if Cnt_reg = 31 then
                     state_next <= do;
                  else
                     Cnt_next <= Cnt_reg+1;
                     state_next <= wait_low_i;
                  end if;
               else
                  state_next <= wait_high_i;
               end if;
            else
               state_next <= idle1;
            end if;

         when do =>
            if Read_bit ='1' then
               if Add_reg(14)='1' then
                  dadd_buf_next <= Add_reg(10 downto 0);
                  state_next <= ini_read_ram;
               else
                  cadd_buf_next <= Add_reg(11 downto 0);
                  state_next <= ini_read_rom;
               end if;
            else
               if Add_reg(14)='1' then
                  dadd_buf_next <= Add_reg(10 downto 0);
                  dout_buf_next <=  Data_reg;
                  state_next <= ini_write_ram;
               else
                  cadd_buf_next <= Add_reg(11 downto 0);
                  cout_buf_next <=  Data_reg(7 downto 0);
                  state_next <= ini_write_rom;
               end if;
               SRo_next <= SRi_reg;
            end if;
         when ini_read_rom =>
            state_next <= read_rom_clk;
         when read_rom_clk =>
            state_next <= read_rom;
         when read_rom =>
            SRo_next <= SRi_reg(31 downto 16) & "00000000" & cin_prg;
            state_next <= end2;
         when ini_read_ram =>
            state_next <= read_ram_clk;
         when read_ram_clk =>
            state_next <= read_ram;
         when read_ram =>
            SRo_next <= SRi_reg(31 downto 16) & din_prg;
            state_next <= end2;
         when ini_write_rom =>
            state_next <= write_rom_clk;
         when write_rom_clk =>
            state_next <= write_rom;
         when write_rom =>
            SRo_next <= SRi_reg;
            state_next <= end1;
         when ini_write_ram =>
            state_next <= write_ram_clk;
         when write_ram_clk =>
            state_next <= write_ram;
         when write_ram =>
            SRo_next <= SRi_reg;
            state_next <= end1;
         when end1 =>
            if CS='1' then
               state_next <= idle1;
            else
               state_next <= end1;
            end if;
         when end2 =>
            if CS='1' then
               state_next <= idle2;
            else
               state_next <= end2;
            end if;
         when idle2 =>
            if CS='0' then
               state_next <= wait_low_o;
            else
               state_next <= idle2;
            end if;
            Cnt_next <= (others=>'0');
         when wait_low_o =>
            if CS='0' then
               if SCK='0' then
                    MISO_buf_next <= SRo_reg(31); 
                    SRo_next <= SRo_reg(30 downto 0) & '0';
                    state_next <= wait_high_o;               
               else
                    state_next <= wait_low_o;
               end if;
            else
               state_next <= idle1;
            end if;
         when wait_high_o =>
            if CS='0' then
               if SCK='1' then                  
                  if Cnt_reg = 31 then
                     state_next <= end1;
                  else
                     Cnt_next <= Cnt_reg+1;
                     state_next <= wait_low_o;
                  end if;
               else
                  state_next <= wait_high_o;
               end if;
            else
               state_next <= idle1;
            end if;
      end case;
   end process;

   -- look-ahead output logic
   process(state_next)
   begin
      pclk_buf_next <= '0';
      cwe_buf_next <= '0';
      dwe_buf_next <= '0';
      
       case state_next is
         when read_rom_clk =>
            pclk_buf_next <= '1';         
         when read_ram_clk =>
            pclk_buf_next <= '1';
         when ini_write_rom =>
            cwe_buf_next <= '1';         
         when write_rom_clk =>
            cwe_buf_next <= '1';
            pclk_buf_next <= '1';
         when write_rom =>
            cwe_buf_next <= '1';         
         when ini_write_ram =>
            dwe_buf_next <= '1';         
         when write_ram_clk =>
            dwe_buf_next <= '1';
            pclk_buf_next <= '1';
         when write_ram =>
            dwe_buf_next <= '1';         
         when others =>
      end case;

   end process;
    
   --  output
   MISO <= MISO_buf_reg;
   cout_prg <= cout_buf_reg;
   cadd_prg <= cadd_buf_reg;
   dout_prg <= dout_buf_reg;
   dadd_prg <= dadd_buf_reg;
   cwe_prg <= cwe_buf_reg;
   dwe_prg <= dwe_buf_reg;
   prog_clk <= pclk_buf_reg; 

end arch;
