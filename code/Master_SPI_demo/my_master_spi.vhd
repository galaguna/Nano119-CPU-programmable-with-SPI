--=============================
-- my_master_spi.vhd
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
-- Componente master_spi4nano
--=============================================================================
-- Author: Gerardo Laguna
-- UAM lerma
-- Mexico
-- 6/06/2025
--=============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity master_spi4nano is
    generic (WORD_SIZE: natural);
   port(
      CLK, RST: in std_logic;
      CS, MOSI, SCK: out std_logic;
      MISO: in std_logic;
      Tx_word: in std_logic_vector(WORD_SIZE-1 downto 0);
      Rx_word: out std_logic_vector(WORD_SIZE-1 downto 0);
      Go: in std_logic;
      Busy: out std_logic
  );
end master_spi4nano;

architecture arch of master_spi4nano is
   type state_type is
      (idle, start, latch_SRo, Dout_ld, LS_SRo, 
      SCK_L,LS_SRi,SCK_H,last_SCK_L, finish);

   signal state_reg, state_next: state_type;
   signal SRi_reg, SRi_next: std_logic_vector(WORD_SIZE-1 downto 0);
   signal SRo_reg, SRo_next: std_logic_vector(WORD_SIZE-1 downto 0);
   signal bCnt_reg, bCnt_next: unsigned(6 downto 0);
   signal wCnt_reg, wCnt_next: unsigned(5 downto 0);

   signal MOSI_buf_reg, MOSI_buf_next: std_logic;
   signal CS_buf_reg, CS_buf_next: std_logic;
   signal SCK_buf_reg, SCK_buf_next: std_logic;
   signal Busy_buf_reg, Busy_buf_next: std_logic;


begin
   -- state & data registers
   process(CLK,RST)
   begin
      if (RST='1') then
         state_reg <= idle;
         SRi_reg <= (others=>'0');
         SRo_reg <= (others=>'0');
         bCnt_reg <= (others=>'0');
         wCnt_reg <= (others=>'0');
         MOSI_buf_reg <= '1';
         CS_buf_reg <= '1';
         SCK_buf_reg <= '1';
         Busy_buf_reg <= '0';

      elsif (CLK'event and CLK='1') then
         state_reg <= state_next;
         SRi_reg <= SRi_next;
         SRo_reg <= SRo_next;
         bCnt_reg <= bCnt_next;
         wCnt_reg <= wCnt_next;
         MOSI_buf_reg <= MOSI_buf_next;
         CS_buf_reg <= CS_buf_next;
         SCK_buf_reg <= SCK_buf_next;
         Busy_buf_reg <= Busy_buf_next; 
      end if;
   end process;
   
   -- next-state logic & data path functional units/routing
   process(state_reg,Go,MISO,Tx_Word,
           SRi_reg,SRo_reg,bCnt_reg,wCnt_reg)
   begin
      SRi_next <= SRi_reg;
      SRo_next <= SRo_reg;
      bCnt_next <= bCnt_reg;
      wCnt_next <= wCnt_reg;

      case state_reg is
         when idle =>
            if Go='1' then
               state_next <= start;
            else
               state_next <= idle;
            end if;
         when start =>
            SRo_next <= Tx_Word;
            SRi_next <= (others=>'0');
            bCnt_next <= (others=>'0');
            state_next <= latch_SRo;

         when latch_SRo =>
            state_next <= Dout_ld;
        
         when Dout_ld =>
            state_next <= LS_SRo;

         when LS_SRo =>
            SRo_next <= SRo_reg(WORD_SIZE-2 downto 0) & '0';
            wCnt_next <= (others=>'0');
            state_next <= SCK_L;

         when SCK_L =>
            if wCnt_reg = 1 then
                state_next <= LS_SRi;
            else
                wCnt_next <= wCnt_reg+1;
                state_next <= SCK_L;
            end if;

         when LS_SRi =>
               SRi_next <= SRi_reg(WORD_SIZE-2 downto 0) & MISO;
               wCnt_next <= (others=>'0');
               state_next <= SCK_H;

         when SCK_H =>
            if wCnt_reg = 2 then
                state_next <= LS_SRi;
                if bCnt_reg = WORD_SIZE-1 then
                    wCnt_next <= (others=>'0');
                    state_next <= last_SCK_L;
                else
                    bCnt_next <= bCnt_reg+1;
                    state_next <= Dout_ld;
                end if;
            else
                wCnt_next <= wCnt_reg+1;
                state_next <= SCK_H;
            end if;

         when last_SCK_L =>
            if wCnt_reg = 4 then
                state_next <= finish;
            else
                wCnt_next <= wCnt_reg+1;
                state_next <= last_SCK_L;
            end if;

         when finish =>
            state_next <= idle;

      end case;
   end process;

   -- look-ahead output logic
   process(state_next)
   begin
      CS_buf_next <= '1';
      SCK_buf_next <= '1';
      Busy_buf_next <= '1';
      MOSI_buf_next <= MOSI_buf_reg;
      
      case state_next is
        when idle =>
            Busy_buf_next <= '0';
              
        when start =>
          
        when latch_SRo =>
            CS_buf_next <= '0';
            SCK_buf_next <= '0';

        when Dout_ld =>
            CS_buf_next <= '0';
            SCK_buf_next <= '0';
            MOSI_buf_next <= SRo_reg(WORD_SIZE-1);
          
        when LS_SRo =>
            CS_buf_next <= '0';
            SCK_buf_next <= '0';
          
        when SCK_L =>
            CS_buf_next <= '0';
            SCK_buf_next <= '0';
          
        when LS_SRi =>
            CS_buf_next <= '0';
          
        when SCK_H =>
            CS_buf_next <= '0';
          
        when last_SCK_L =>
            CS_buf_next <= '0';
            SCK_buf_next <= '0';
          
        when finish =>
            Busy_buf_next <= '0';
          
      end case;
   end process;

   --  output
   
   MOSI <= MOSI_buf_reg;
   CS <= CS_buf_reg;
   SCK <= SCK_buf_reg;
   Rx_word <= SRi_reg;
   Busy <= Busy_buf_reg;

end arch;
