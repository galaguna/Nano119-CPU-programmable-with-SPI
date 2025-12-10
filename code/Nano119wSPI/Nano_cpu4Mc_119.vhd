--=============================================================================
-- Entidad para la Maquina Nano (CPU Nano) 
--=============================================================================
-- Codigo beta V4c con conjunto de 119 instrucciones codificadas de conformidad con
-- la lista objetivo (target 119)
--=============================================================================
-- Author: Gerardo A. Laguna S.
-- Universidad Autonoma Metropolitana
-- Unidad Lerma
-- 26.nov.2025
-------------------------------------------------------------------------------
-- Library declarations
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- Entity declaration
-------------------------------------------------------------------------------
entity Nano_cpu is
   port(
   clk, reset : in std_logic;
   run        : in std_logic;
   state      : out std_logic_vector(7 downto 0);
   flags      : out std_logic_vector(7 downto 0);
   code_add   : out std_logic_vector(11 downto 0);
   code       : in std_logic_vector(7 downto 0);
   data_add   : out std_logic_vector(10 downto 0);
   din        : in std_logic_vector(15 downto 0);
   dout       : out std_logic_vector(15 downto 0);
   data_we    : out std_logic;
   stk_add    : out std_logic_vector(7 downto 0);
   sin        : in std_logic_vector(15 downto 0);
   sout       : out std_logic_vector(15 downto 0);
   stk_we     : out std_logic;
   io_add     : out std_logic_vector(7 downto 0);
   io_i       : in std_logic_vector(7 downto 0);
   io_o       : out std_logic_vector(7 downto 0);
   io_we      : out std_logic;
   int0,int1,int2 : in std_logic;
   r_out      : out std_logic_vector(31 downto 0)
  );
end Nano_cpu;

architecture my_arch of Nano_cpu is
-------------------------------------------------------------------------------
-- Constant declaration
-------------------------------------------------------------------------------
-- Size constants: 
   constant CODE_ADD_SIZE    :  integer := 12;
   constant CODE_SIZE        :  integer := 8;
   constant DATA_ADD_SIZE    :  integer := 11;
   constant INT0_VEC_ADD     :  unsigned(15 downto 0):= x"0FFD"; 
   constant INT1_VEC_ADD     :  unsigned(15 downto 0):= x"0FFA"; 
   constant INT2_VEC_ADD     :  unsigned(15 downto 0):= x"0FF7"; 

-- Machine State codes: 
   constant stop             :  std_logic_vector(7 downto 0):= x"00";
   constant start            :  std_logic_vector(7 downto 0):= x"01";
   constant fetch_decode     :  std_logic_vector(7 downto 0):= x"02";
   constant load_ha_jmp      :  std_logic_vector(7 downto 0):= x"03";
   constant load_la_jmp      :  std_logic_vector(7 downto 0):= x"04";
   constant load_ip          :  std_logic_vector(7 downto 0):= x"05";
   constant jz16_exe         :  std_logic_vector(7 downto 0):= x"06";
   constant jz32_exe         :  std_logic_vector(7 downto 0):= x"07";
   constant jn16_exe         :  std_logic_vector(7 downto 0):= x"08";
   constant jn32_exe         :  std_logic_vector(7 downto 0):= x"09";
   constant jo16_exe         :  std_logic_vector(7 downto 0):= x"0A";
   constant jo32_exe         :  std_logic_vector(7 downto 0):= x"0B";
   constant jco16_exe        :  std_logic_vector(7 downto 0):= x"0C";
   constant jco32_exe        :  std_logic_vector(7 downto 0):= x"0D";
   constant load_ha_call     :  std_logic_vector(7 downto 0):= x"0E";
   constant load_la_call     :  std_logic_vector(7 downto 0):= x"0F";
   constant push_ip          :  std_logic_vector(7 downto 0):= x"10";
   constant pop_ip_ini       :  std_logic_vector(7 downto 0):= x"11";
   constant pop_ip           :  std_logic_vector(7 downto 0):= x"12";
   constant ini_reti         :  std_logic_vector(7 downto 0):= x"13";
   constant pusha_exe        :  std_logic_vector(7 downto 0):= x"14";
   constant pushb_exe        :  std_logic_vector(7 downto 0):= x"15";
   constant dec_spx          :  std_logic_vector(7 downto 0):= x"16";
   constant point_spx        :  std_logic_vector(7 downto 0):= x"17";
   constant popa_exe         :  std_logic_vector(7 downto 0):= x"18";
   constant popb_exe         :  std_logic_vector(7 downto 0):= x"19";
   constant load_khx         :  std_logic_vector(7 downto 0):= x"1A";
   constant load_klx         :  std_logic_vector(7 downto 0):= x"1B";
   constant store_ka         :  std_logic_vector(7 downto 0):= x"1C";
   constant store_kb         :  std_logic_vector(7 downto 0):= x"1D";
   constant load_usp         :  std_logic_vector(7 downto 0):= x"1E";
   constant load_hi_movxm    :  std_logic_vector(7 downto 0):= x"1F";
   constant load_li_movxm    :  std_logic_vector(7 downto 0):= x"20";
   constant load_dp_movxm    :  std_logic_vector(7 downto 0):= x"21";
   constant movam_exe        :  std_logic_vector(7 downto 0):= x"22";
   constant movbm_exe        :  std_logic_vector(7 downto 0):= x"23";
   constant movrlm_exe       :  std_logic_vector(7 downto 0):= x"24";
   constant movrhm_exe       :  std_logic_vector(7 downto 0):= x"25";
   constant load_hi_movmx    :  std_logic_vector(7 downto 0):= x"26";
   constant load_li_movmx    :  std_logic_vector(7 downto 0):= x"27";
   constant load_dp_movmx    :  std_logic_vector(7 downto 0):= x"28";
   constant movma_exe        :  std_logic_vector(7 downto 0):= x"29";
   constant movmb_exe        :  std_logic_vector(7 downto 0):= x"2A";
   constant load_hi_movi     :  std_logic_vector(7 downto 0):= x"2B";
   constant load_li_movi     :  std_logic_vector(7 downto 0):= x"2C";
   constant load_dp_movi     :  std_logic_vector(7 downto 0):= x"2D";
   constant load_ix          :  std_logic_vector(7 downto 0):= x"2E";
   constant movia_exe        :  std_logic_vector(7 downto 0):= x"2F";
   constant movib_exe        :  std_logic_vector(7 downto 0):= x"30";
   constant movaipp_exe      :  std_logic_vector(7 downto 0):= x"31";
   constant movbipp_exe      :  std_logic_vector(7 downto 0):= x"32";
   constant movrlipp_exe     :  std_logic_vector(7 downto 0):= x"33";
   constant movrhipp_exe     :  std_logic_vector(7 downto 0):= x"34";
   constant ix_inc           :  std_logic_vector(7 downto 0):= x"35";
   constant ix_sto           :  std_logic_vector(7 downto 0):= x"36";
   constant movippa_exe      :  std_logic_vector(7 downto 0):= x"37";
   constant movippb_exe      :  std_logic_vector(7 downto 0):= x"38";
   constant ix_dec_a         :  std_logic_vector(7 downto 0):= x"39";
   constant movmmia_exe      :  std_logic_vector(7 downto 0):= x"3A";
   constant ix_dec_b         :  std_logic_vector(7 downto 0):= x"3B";
   constant movmmib_exe      :  std_logic_vector(7 downto 0):= x"3C";
   constant ix_dest          :  std_logic_vector(7 downto 0):= x"3D";
   constant movas_exe        :  std_logic_vector(7 downto 0):= x"3E";
   constant movbs_exe        :  std_logic_vector(7 downto 0):= x"3F";
   constant movrls_exe       :  std_logic_vector(7 downto 0):= x"40";
   constant movrhs_exe       :  std_logic_vector(7 downto 0):= x"41";
   constant movsa_exe        :  std_logic_vector(7 downto 0):= x"42";
   constant movsb_exe        :  std_logic_vector(7 downto 0):= x"43";
   constant add_result       :  std_logic_vector(7 downto 0):= x"44";
   constant cmp_result       :  std_logic_vector(7 downto 0):= x"45";
   constant xmul_exe         :  std_logic_vector(7 downto 0):= x"46";
   constant sxacc_exe        :  std_logic_vector(7 downto 0):= x"47";
   constant log_result       :  std_logic_vector(7 downto 0):= x"48";
   constant store_ki         :  std_logic_vector(7 downto 0):= x"49";
   constant store_kj         :  std_logic_vector(7 downto 0):= x"4A";
   constant store_kn         :  std_logic_vector(7 downto 0):= x"4B";
   constant store_km         :  std_logic_vector(7 downto 0):= x"4C";
   constant pushi_exe        :  std_logic_vector(7 downto 0):= x"4D";
   constant pushj_exe        :  std_logic_vector(7 downto 0):= x"4E";
   constant pushn_exe        :  std_logic_vector(7 downto 0):= x"4F";
   constant pushm_exe        :  std_logic_vector(7 downto 0):= x"50";
   constant popi_exe         :  std_logic_vector(7 downto 0):= x"51";
   constant popj_exe         :  std_logic_vector(7 downto 0):= x"52";
   constant popn_exe         :  std_logic_vector(7 downto 0):= x"53";
   constant popm_exe         :  std_logic_vector(7 downto 0):= x"54";
   constant load_xpp         :  std_logic_vector(7 downto 0):= x"55";
   constant load_xmm         :  std_logic_vector(7 downto 0):= x"56";
   constant movxrm           :  std_logic_vector(7 downto 0):= x"57";
   constant load_y           :  std_logic_vector(7 downto 0):= x"58";
   constant cmp_xy           :  std_logic_vector(7 downto 0):= x"59";
   constant jnz16_exe        :  std_logic_vector(7 downto 0):= x"5A";
   constant jnz32_exe        :  std_logic_vector(7 downto 0):= x"5B";
   constant jp16_exe         :  std_logic_vector(7 downto 0):= x"5C";
   constant jp32_exe         :  std_logic_vector(7 downto 0):= x"5D";
   constant jno16_exe        :  std_logic_vector(7 downto 0):= x"5E";
   constant jno32_exe        :  std_logic_vector(7 downto 0):= x"5F";
   constant jnco16_exe       :  std_logic_vector(7 downto 0):= x"60";
   constant jnco32_exe       :  std_logic_vector(7 downto 0):= x"61";
   constant load_ioadd       :  std_logic_vector(7 downto 0):= x"62";
   constant outa_exe         :  std_logic_vector(7 downto 0):= x"63";
   constant ina_exe          :  std_logic_vector(7 downto 0):= x"64";
   constant load_iok         :  std_logic_vector(7 downto 0):= x"65";
   constant ld_ioadd4k       :  std_logic_vector(7 downto 0):= x"66";
   constant outk_exe         :  std_logic_vector(7 downto 0):= x"67";
   constant ini_iss          :  std_logic_vector(7 downto 0):= x"68";
   constant in_intx_F        :  std_logic_vector(7 downto 0):= x"69";
   constant set_int0_F       :  std_logic_vector(7 downto 0):= x"6A";
   constant set_int1_F       :  std_logic_vector(7 downto 0):= x"6B";
   constant set_int2_F       :  std_logic_vector(7 downto 0):= x"6C";
   constant ld_iss_vec       :  std_logic_vector(7 downto 0):= x"6D";
   constant push_ip_int      :  std_logic_vector(7 downto 0):= x"6E";
   constant push_rl          :  std_logic_vector(7 downto 0):= x"6F";
   constant push_rh          :  std_logic_vector(7 downto 0):= x"70";
   constant push_f           :  std_logic_vector(7 downto 0):= x"71";
   constant pop_f            :  std_logic_vector(7 downto 0):= x"72";
   constant pop_rh_ini       :  std_logic_vector(7 downto 0):= x"73";
   constant pop_rh           :  std_logic_vector(7 downto 0):= x"74";
   constant pop_rl_ini       :  std_logic_vector(7 downto 0):= x"75";
   constant pop_rl_nres      :  std_logic_vector(7 downto 0):= x"76";

-- Instruction Codes:
   constant nop_code         :  std_logic_vector(7 downto 0):= x"00"; --No op.
   constant jmp_code         :  std_logic_vector(7 downto 0):= x"01"; --Inconditional jump
   constant jz16_code        :  std_logic_vector(7 downto 0):= x"02"; --Jump if zero for 16 bits word
   constant jn16_code        :  std_logic_vector(7 downto 0):= x"03"; --Jump if negative for 16 bits word
   constant jo16_code        :  std_logic_vector(7 downto 0):= x"04"; --Jump if aritmetic overflow for 16 bits word
   constant jco16_code       :  std_logic_vector(7 downto 0):= x"05"; --Jump if catastrofic aritmetic overflow for 16 bits word
   constant jz32_code        :  std_logic_vector(7 downto 0):= x"06"; --Jump if zero for 32 bits word
   constant jn32_code        :  std_logic_vector(7 downto 0):= x"07"; --Jump if negative for 32 bits word
   constant jo32_code        :  std_logic_vector(7 downto 0):= x"08"; --Jump if aritmetic overflow for 32 bits word
   constant jco32_code       :  std_logic_vector(7 downto 0):= x"09"; --Jump if catastrofic aritmetic overflow for 32 bits word
   constant jnz16_code       :  std_logic_vector(7 downto 0):= x"0A"; --Jump if nonzero for 16 bits word
   constant jp16_code        :  std_logic_vector(7 downto 0):= x"0B"; --Jump if positive for 16 bits word
   constant jno16_code       :  std_logic_vector(7 downto 0):= x"0C"; --Jump if not aritmetic overflow for 16 bits word
   constant jnco16_code      :  std_logic_vector(7 downto 0):= x"0D"; --Jump if not catastrofic aritmetic overflow for 16 bits word
   constant jnz32_code       :  std_logic_vector(7 downto 0):= x"0E"; --Jump if nonzero for 32 bits word
   constant jp32_code        :  std_logic_vector(7 downto 0):= x"0F"; --Jump if positive for 32 bits word
   constant jno32_code       :  std_logic_vector(7 downto 0):= x"10"; --Jump if not aritmetic overflow for 32 bits word
   constant jnco32_code      :  std_logic_vector(7 downto 0):= x"11"; --Jump if not catastrofic aritmetic overflow for 32 bits word
   constant call_code        :  std_logic_vector(7 downto 0):= x"12"; --Call
   constant ret_code         :  std_logic_vector(7 downto 0):= x"13"; --Return from call
   constant reti_code        :  std_logic_vector(7 downto 0):= x"14"; --Return from interrupt
   constant pusha_code       :  std_logic_vector(7 downto 0):= x"15"; --Push A
   constant pushb_code       :  std_logic_vector(7 downto 0):= x"16"; --Push B
   constant pushi_code       :  std_logic_vector(7 downto 0):= x"17"; --Push I
   constant pushj_code       :  std_logic_vector(7 downto 0):= x"18"; --Push J
   constant pushn_code       :  std_logic_vector(7 downto 0):= x"19"; --Push N
   constant pushm_code       :  std_logic_vector(7 downto 0):= x"1A"; --Push M
   constant popa_code        :  std_logic_vector(7 downto 0):= x"1B"; --Pop A
   constant popb_code        :  std_logic_vector(7 downto 0):= x"1C"; --Pop B
   constant popi_code        :  std_logic_vector(7 downto 0):= x"1D"; --Pop I
   constant popj_code        :  std_logic_vector(7 downto 0):= x"1E"; --Pop J
   constant popn_code        :  std_logic_vector(7 downto 0):= x"1F"; --Pop N
   constant popm_code        :  std_logic_vector(7 downto 0):= x"20"; --Pop M
   constant movba_code       :  std_logic_vector(7 downto 0):= x"21"; --MOV B, A
   constant movira_code      :  std_logic_vector(7 downto 0):= x"22"; --MOV I, A
   constant movjra_code      :  std_logic_vector(7 downto 0):= x"23"; --MOV J, A
   constant movrla_code      :  std_logic_vector(7 downto 0):= x"24"; --MOV RL, A
   constant movrha_code      :  std_logic_vector(7 downto 0):= x"25"; --MOV RH, A
   constant movab_code       :  std_logic_vector(7 downto 0):= x"26"; --MOV A, B
   constant movrlb_code      :  std_logic_vector(7 downto 0):= x"27"; --MOV RL, B
   constant movrhb_code      :  std_logic_vector(7 downto 0):= x"28"; --MOV RH, B
   constant movracc_code     :  std_logic_vector(7 downto 0):= x"29"; --MOV R, ACC
   constant movaaccl_code    :  std_logic_vector(7 downto 0):= x"2A"; --MOV A, ACCL
   constant movbaccl_code    :  std_logic_vector(7 downto 0):= x"2B"; --MOV B, ACCL
   constant movaacch_code    :  std_logic_vector(7 downto 0):= x"2C"; --MOV A, ACCH
   constant movbacch_code    :  std_logic_vector(7 downto 0):= x"2D"; --MOV B, ACCH
   constant movaccla_code    :  std_logic_vector(7 downto 0):= x"2E"; --MOV ACCL, A
   constant movacclb_code    :  std_logic_vector(7 downto 0):= x"2F"; --MOV ACCL, B
   constant movaccha_code    :  std_logic_vector(7 downto 0):= x"30"; --MOV ACCH, A
   constant movacchb_code    :  std_logic_vector(7 downto 0):= x"31"; --MOV ACCH, B
   constant stospa_code      :  std_logic_vector(7 downto 0):= x"32"; --STO SP, A (i.e. MOV SP, A)
   constant stospb_code      :  std_logic_vector(7 downto 0):= x"33"; --STO SP, B (i.e. MOV SP, B)
   constant stouspa_code     :  std_logic_vector(7 downto 0):= x"34"; --STO USP, A (i.e. MOV USP, A)
   constant stouspb_code     :  std_logic_vector(7 downto 0):= x"35"; --STO USP, B (i.e. MOV USP, B)
   constant ldusp_code       :  std_logic_vector(7 downto 0):= x"36"; --LOAD USP, SP  (i.e. MOV SP, USP)
   constant lduspa_code      :  std_logic_vector(7 downto 0):= x"37"; --LOAD USP, AL (i.e. MOV AL, USP)
   constant lduspb_code      :  std_logic_vector(7 downto 0):= x"38"; --LOAD USP, BL (i.e. MOV BL, USP)
   constant lduspr_code      :  std_logic_vector(7 downto 0):= x"39"; --LOAD USP, RL (i.e. MOV R(7:0), USP)  
   constant lduspk_code      :  std_logic_vector(7 downto 0):= x"3A"; --LOAD USP, k (i.e. MOV k, USP)
   constant movka_code       :  std_logic_vector(7 downto 0):= x"3B"; --MOV k, A
   constant movkb_code       :  std_logic_vector(7 downto 0):= x"3C"; --MOV k, B
   constant movki_code       :  std_logic_vector(7 downto 0):= x"3D"; --MOV k, I
   constant movkj_code       :  std_logic_vector(7 downto 0):= x"3E"; --MOV k, J
   constant movkn_code       :  std_logic_vector(7 downto 0):= x"3F"; --MOV k, N
   constant movkm_code       :  std_logic_vector(7 downto 0):= x"40"; --MOV k, M
   constant movam_code       :  std_logic_vector(7 downto 0):= x"41"; --MOV A, RAM[ix]
   constant movbm_code       :  std_logic_vector(7 downto 0):= x"42"; --MOV B, RAM[ix]
   constant movrlm_code      :  std_logic_vector(7 downto 0):= x"43"; --MOV RL, RAM[ix]
   constant movrhm_code      :  std_logic_vector(7 downto 0):= x"44"; --MOV RH, RAM[ix]
   constant movma_code       :  std_logic_vector(7 downto 0):= x"45"; --MOV RAM[ix], A
   constant movmb_code       :  std_logic_vector(7 downto 0):= x"46"; --MOV RAM[ix], B
   constant movai_code       :  std_logic_vector(7 downto 0):= x"47"; --MOV A, RAM[ix]->
   constant movbi_code       :  std_logic_vector(7 downto 0):= x"48"; --MOV B, RAM[ix]->
   constant movrli_code      :  std_logic_vector(7 downto 0):= x"49"; --MOV RL, RAM[ix]->
   constant movrhi_code      :  std_logic_vector(7 downto 0):= x"4A"; --MOV RH, RAM[ix]->
   constant movia_code       :  std_logic_vector(7 downto 0):= x"4B"; --MOV RAM[ix]->, A
   constant movib_code       :  std_logic_vector(7 downto 0):= x"4C"; --MOV RAM[ix]->, B
   constant movaipp_code     :  std_logic_vector(7 downto 0):= x"4D"; --MOV A, RAM[ix++]->
   constant movbipp_code     :  std_logic_vector(7 downto 0):= x"4E"; --MOV B, RAM[ix++]->
   constant movrlipp_code    :  std_logic_vector(7 downto 0):= x"4F"; --MOV RL, RAM[ix++]->
   constant movrhipp_code    :  std_logic_vector(7 downto 0):= x"50"; --MOV RH, RAM[ix++]->
   constant movippa_code     :  std_logic_vector(7 downto 0):= x"51"; --MOV RAM[ix++]->, A
   constant movippb_code     :  std_logic_vector(7 downto 0):= x"52"; --MOV RAM[ix++]->, B
   constant movmmia_code     :  std_logic_vector(7 downto 0):= x"53"; --MOV RAM[--ix]->, A
   constant movmmib_code     :  std_logic_vector(7 downto 0):= x"54"; --MOV RAM[--ix]->, B
   constant movas_code       :  std_logic_vector(7 downto 0):= x"55"; --MOV A, STACK[usp]
   constant movbs_code       :  std_logic_vector(7 downto 0):= x"56"; --MOV B, STACK[usp]
   constant movrls_code      :  std_logic_vector(7 downto 0):= x"57"; --MOV RL, STACK[usp]
   constant movrhs_code      :  std_logic_vector(7 downto 0):= x"58"; --MOV RH, STACK[usp]
   constant movsa_code       :  std_logic_vector(7 downto 0):= x"59"; --MOV STACK[usp], A
   constant movsb_code       :  std_logic_vector(7 downto 0):= x"5A"; --MOV STACK[usp], B
   constant uadd_code        :  std_logic_vector(7 downto 0):= x"5B"; --A, B de 16 bits, sin signo, y R de 32 bits: R = UADD A,B 
   constant sadd_code        :  std_logic_vector(7 downto 0):= x"5C"; --A, B de 16 bits, con signo, y R de 32 bits: R = SADD A,B 
   constant ac_code          :  std_logic_vector(7 downto 0):= x"5D"; --ACC y R de 32 bits: ACC = ADD ACC,R 
   constant umul_code        :  std_logic_vector(7 downto 0):= x"5E"; --A, B de 16 bits, sin signo, y R de 32 bits: R = UMUL A,B 
   constant smul_code        :  std_logic_vector(7 downto 0):= x"5F"; --A, B de 16 bits, con signo, y R de 32 bits: R = SMUL A,B 
   constant umac_code        :  std_logic_vector(7 downto 0):= x"60"; --A, B de 16 bits, sin signo, y R de 32 bits: R = UMUL A,B; ACC = ADD ACC,R 
   constant smac_code        :  std_logic_vector(7 downto 0):= x"61"; --A, B de 16 bits, con signo, y R de 32 bits: R = SMUL A,B; ACC = ADD ACC,R 
   constant sracc_code       :  std_logic_vector(7 downto 0):= x"62"; -- R = right shift ACC in A positions 
   constant sraacc_code      :  std_logic_vector(7 downto 0):= x"63"; -- R = arithmetic right shift ACC in A positions 
   constant slacc_code       :  std_logic_vector(7 downto 0):= x"64"; -- R = left shift ACC in A positions 
   constant nota_code        :  std_logic_vector(7 downto 0):= x"65"; --A de 16 bits: RL = not A 
   constant notb_code        :  std_logic_vector(7 downto 0):= x"66"; --A de 16 bits: RL = not B
   constant and_code         :  std_logic_vector(7 downto 0):= x"67"; --A, B y R de 16 bits: RL = A AND B 
   constant or_code          :  std_logic_vector(7 downto 0):= x"68"; --A, B y R de 16 bits: RL = A OR B
   constant xor_code         :  std_logic_vector(7 downto 0):= x"69"; --A, B y R de 16 bits: RL = A XOR B
   constant incusp_code      :  std_logic_vector(7 downto 0):= x"6A"; --INC USP   
   constant incir_code       :  std_logic_vector(7 downto 0):= x"6B"; --INC I   
   constant incjr_code       :  std_logic_vector(7 downto 0):= x"6C"; --INC J   
   constant decusp_code      :  std_logic_vector(7 downto 0):= x"6D"; --DEC USP   
   constant decir_code       :  std_logic_vector(7 downto 0):= x"6E"; --DEC I   
   constant decjr_code       :  std_logic_vector(7 downto 0):= x"6F"; --DEC J   
   constant cmpin_code       :  std_logic_vector(7 downto 0):= x"70"; --CMP I,N  (Compare I with N, i.e. R=I-N)
   constant cmpjm_code       :  std_logic_vector(7 downto 0):= x"71"; --CMP J,M  (Compare J with M, i.e. R=J-M)
   constant incmpm_code      :  std_logic_vector(7 downto 0):= x"72"; --INCMP M[i],M[i+1]  (Increment M[i] and compare with M[i+1], i.e. M[i]= M[i]+1; R=M[i]-M[i+1])
   constant decmpm_code      :  std_logic_vector(7 downto 0):= x"73"; --DECMP M[i],M[i+1]  (Decrement M[i] and compare with M[i+1], i.e. M[i]= M[i]-1; R=M[i]-M[i+1])
   constant outa_code        :  std_logic_vector(7 downto 0):= x"74"; --MOV AL, Port[ix]
   constant ina_code         :  std_logic_vector(7 downto 0):= x"75"; --MOV Port[ix], AL 
   constant outk_code        :  std_logic_vector(7 downto 0):= x"76"; --MOV k, Port[ix]
   constant stop_code        :  std_logic_vector(7 downto 0):= x"FF"; --Stop instruction

-------------------------------------------------------------------------------
-- Signal declaration
-------------------------------------------------------------------------------
-- Control path register
   signal state_reg, state_next            : std_logic_vector(7 downto 0);
-- Data path registers
   signal IP_reg, IP_next                  : unsigned(11 downto 0);
   signal DP_reg, DP_next                  : unsigned(10 downto 0);
   signal DPB_reg, DPB_next                : unsigned(10 downto 0);
   signal UDP_reg, UDP_next                : unsigned(10 downto 0);
   signal SP_reg, SP_next                  : unsigned(7 downto 0);
   signal USP_reg, USP_next                : unsigned(7 downto 0);
   signal PP_reg, PP_next                  : unsigned(7 downto 0);   
   signal instruction_reg,instruction_next : std_logic_vector(7 downto 0);
   signal H_reg, H_next                    : unsigned(7 downto 0);
   signal L_reg, L_next                    : unsigned(7 downto 0);
   signal A_reg, A_next                    : unsigned(15 downto 0);
   signal B_reg, B_next                    : unsigned(15 downto 0);
   signal X_reg, X_next                    : unsigned(15 downto 0);
   signal Y_reg, Y_next                    : unsigned(15 downto 0);

   signal R_reg, R_next                    : unsigned(31 downto 0);
   Alias  RL_reg                           : unsigned is R_reg(15 downto 0);
   Alias  RH_reg                           : unsigned is R_reg(31 downto 16);
   Alias  RL_next                          : unsigned is R_next(15 downto 0);
   Alias  RH_next                          : unsigned is R_next(31 downto 16);

   signal ACC_reg, ACC_next                : unsigned(31 downto 0);
   Alias  ACCL_reg                         : unsigned is ACC_reg(15 downto 0);
   Alias  ACCH_reg                         : unsigned is ACC_reg(31 downto 16);
   Alias  ACCL_next                        : unsigned is ACC_next(15 downto 0);
   Alias  ACCH_next                        : unsigned is ACC_next(31 downto 16);

   signal WR33_reg, WR33_next              : unsigned(32 downto 0);
   signal SR1_reg, SR1_next                : unsigned(32 downto 0);
   signal SR2_reg, SR2_next                : unsigned(32 downto 0);

   signal F_reg, F_next                    : std_logic_vector(7 downto 0);

   Alias F_Z16_reg                         : std_logic is F_reg(0);
   Alias F_N16_reg                         : std_logic is F_reg(1);
   Alias F_O16_reg                         : std_logic is F_reg(2);
   Alias F_CO16_reg                        : std_logic is F_reg(3);

   Alias F_Z16_next                        : std_logic is F_next(0);
   Alias F_N16_next                        : std_logic is F_next(1);
   Alias F_O16_next                        : std_logic is F_next(2);
   Alias F_CO16_next                       : std_logic is F_next(3);

   Alias F_Z32_reg                         : std_logic is F_reg(4);
   Alias F_N32_reg                         : std_logic is F_reg(5);
   Alias F_O32_reg                         : std_logic is F_reg(6);
   Alias F_CO32_reg                        : std_logic is F_reg(7);

   Alias F_Z32_next                        : std_logic is F_next(4);
   Alias F_N32_next                        : std_logic is F_next(5);
   Alias F_O32_next                        : std_logic is F_next(6);
   Alias F_CO32_next                       : std_logic is F_next(7);

   signal CNT_reg, CNT_next                : unsigned(5 downto 0);

   signal I_reg, I_next                    : unsigned(15 downto 0);
   signal J_reg, J_next                    : unsigned(15 downto 0);
   signal N_reg, N_next                    : unsigned(15 downto 0);
   signal M_reg, M_next                    : unsigned(15 downto 0);

   signal ISF_reg, ISF_next                : std_logic;
   signal FDI_reg, FDI_next                : std_logic;

--Registers for control signals:
   signal ramwe_reg, ramwe_next            : std_logic;
   signal stkwe_reg, stkwe_next            : std_logic;
   signal iowe_reg, iowe_next              : std_logic;

-------------------------------------------------------------------------------
-- Begin
-------------------------------------------------------------------------------
begin
   -- state & data registers
   process(clk,reset)
   begin
      if (reset='1') then
         state_reg <= stop;
         IP_reg <= (others=>'0');
         DP_reg <= (others=>'0');
         DPB_reg <= (others=>'0');
         UDP_reg <= (others=>'0');
         SP_reg <= (others=>'0');
         USP_reg <= (others=>'0');
         PP_reg <= (others=>'0');
         instruction_reg <= (others=>'0');
         H_reg <= (others=>'0');
         L_reg <= (others=>'0');
         A_reg <= (others=>'0');
         B_reg <= (others=>'0');
         X_reg <= (others=>'0');
         Y_reg <= (others=>'0');
         R_reg <= (others=>'0');
         ACC_reg <= (others=>'0');
         SR1_reg <= (others=>'0');
         SR2_reg <= (others=>'0');
         WR33_reg <= (others=>'0');
         F_reg <= (others=>'0');
         CNT_reg <= (others=>'0');
         I_reg <= (others=>'0');
         J_reg <= (others=>'0');
         N_reg <= (others=>'0');
         M_reg <= (others=>'0');
         ISF_reg <= '0';
         FDI_reg <= '0';
         ramwe_reg <= '0';
         stkwe_reg <= '0';
         iowe_reg <= '0';
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
         IP_reg <= IP_next;
         DP_reg <= DP_next;
         DPB_reg <= DPB_next;
         UDP_reg <= UDP_next;
         SP_reg <= SP_next;
         USP_reg <= USP_next;
         PP_reg <= PP_next;
         instruction_reg <= instruction_next;
         H_reg <= H_next;
         L_reg <= L_next;
         A_reg <= A_next;
         B_reg <= B_next;
         X_reg <= X_next;
         Y_reg <= Y_next;
         R_reg <= R_next;
         ACC_reg <= ACC_next;
         SR1_reg <= SR1_next;
         SR2_reg <= SR2_next;
         WR33_reg <= WR33_next;
         F_reg <= F_next;         
         CNT_reg <= CNT_next;         
         I_reg <= I_next;
         J_reg <= J_next;
         N_reg <= N_next;
         M_reg <= M_next;
         ISF_reg <= ISF_next;
         FDI_reg <= FDI_next;
         ramwe_reg <= ramwe_next;
         stkwe_reg <= stkwe_next;
         iowe_reg <= iowe_next;
      end if;
   end process;

   -- next-state logic & data path functional units/routing
   process(state_reg,run,code,din,sin,io_i,int0,int1,int2, 
           IP_reg,DP_reg,DPB_reg,UDP_reg,SP_reg,USP_reg,PP_reg,instruction_reg,H_reg,L_reg,
           A_reg,B_reg,X_reg,Y_reg,R_reg,ACC_reg,SR1_reg,SR2_reg,WR33_reg,F_reg,CNT_reg,I_reg,J_reg,N_reg,M_reg,ISF_reg,FDI_reg)
   begin
      IP_next <= IP_reg;
      DP_next <= DP_reg;
      DPB_next <= DPB_reg;
      UDP_next <= UDP_reg;
      SP_next <= SP_reg;
      USP_next <= USP_reg;
      PP_next <= PP_reg;
      instruction_next <= instruction_reg;
      H_next <= H_reg;
      L_next <= L_reg;
      A_next <= A_reg;
      B_next <= B_reg;
      X_next <= X_reg;
      Y_next <= Y_reg;
      R_next <= R_reg;
      ACC_next <= ACC_reg;
      SR1_next <= SR1_reg;
      SR2_next <= SR2_reg;
      WR33_next <= WR33_reg;
      F_next <= F_reg;
      CNT_next <= CNT_reg;
      I_next <= I_reg;
      J_next <= J_reg;
      N_next <= N_reg;
      M_next <= M_reg;
      ISF_next <= ISF_reg;
      FDI_next <= FDI_reg;
      
      --Default values for Moore outputs:
      dout <= (others=>'0');
      sout <= (others=>'0');
      io_o <= (others=>'0');
      
      case state_reg is
         when stop =>
            if run='1' then
               state_next <= start;
            else
               if (int0='1' or int1='1' or int2='1')  then
                  state_next <= ini_iss;               
               else
                  state_next <= stop;
               end if;
            end if;
         when start =>
            IP_next <= (others=>'0');
            SP_next <= (others=>'0');
            state_next <= fetch_decode;
         when fetch_decode =>
            instruction_next <= code;
            IP_next <= IP_reg + 1;
            
            if  ((ISF_reg = '0') and (int0='1' or int1='1' or int2='1'))  then
                  FDI_next <= '1';
                  state_next <= ini_iss;               
            else
              case code is
                when nop_code =>
                    state_next <= fetch_decode;
                when jmp_code =>
                    state_next <= load_ha_jmp;
                when jz16_code =>
                    state_next <= jz16_exe;
                when jz32_code =>
                    state_next <= jz32_exe;
                when jn16_code =>
                    state_next <= jn16_exe;
                when jn32_code =>
                    state_next <= jn32_exe;
                when jo16_code =>
                    state_next <= jo16_exe;
                when jo32_code =>
                    state_next <= jo32_exe;
                when jco16_code =>
                    state_next <= jco16_exe;
                when jco32_code =>
                    state_next <= jco32_exe;
                when jnz16_code =>
                    state_next <= jnz16_exe;
                when jnz32_code =>
                    state_next <= jnz32_exe;
                when jp16_code =>
                    state_next <= jp16_exe;
                when jp32_code =>
                    state_next <= jp32_exe;
                when jno16_code =>
                    state_next <= jno16_exe;
                when jno32_code =>
                    state_next <= jno32_exe;
                when jnco16_code =>
                    state_next <= jnco16_exe;
                when jnco32_code =>
                    state_next <= jnco32_exe;
                when call_code =>
                    state_next <= load_ha_call;
                when ret_code =>
                    state_next <= pop_ip_ini;
                when reti_code =>
                    state_next <= ini_reti;
                when pusha_code =>
                    state_next <= pusha_exe;
                when pushb_code =>
                    state_next <= pushb_exe;
                when popa_code =>
                    state_next <= dec_spx;
                when popb_code =>
                    state_next <= dec_spx;
                when movab_code =>
                    B_next <= A_reg;
                    state_next <= fetch_decode;
                when movba_code =>
                    A_next <= B_reg;
                    state_next <= fetch_decode;
                when movira_code =>
                    A_next <= I_reg;
                    state_next <= fetch_decode;
                when movjra_code =>
                    A_next <= J_reg;
                    state_next <= fetch_decode;
                when incir_code =>
                    I_next <= I_reg+1;
                    state_next <= fetch_decode;
                when incjr_code =>
                    J_next <= J_reg+1;
                    state_next <= fetch_decode;
                when decir_code =>
                    I_next <= I_reg-1;
                    state_next <= fetch_decode;
                when decjr_code =>
                    J_next <= J_reg-1;
                    state_next <= fetch_decode;
                when pushi_code =>
                    state_next <= pushi_exe;
                when pushj_code =>
                    state_next <= pushj_exe;
                when pushn_code =>
                    state_next <= pushn_exe;
                when pushm_code =>
                    state_next <= pushm_exe;
                when popi_code =>
                    state_next <= dec_spx;
                when popj_code =>
                    state_next <= dec_spx;
                when popn_code =>
                    state_next <= dec_spx;
                when popm_code =>
                    state_next <= dec_spx;
                when movrla_code =>
                    A_next <= RL_reg;
                    state_next <= fetch_decode;
                when movrha_code =>
                    A_next <= RH_reg;
                    state_next <= fetch_decode;
                when movrlb_code =>
                    B_next <= RL_reg;
                    state_next <= fetch_decode;
                when movrhb_code =>
                    B_next <= RH_reg;
                    state_next <= fetch_decode;
                when movracc_code =>
                    ACC_next <= R_reg;
                    state_next <= fetch_decode;
                when movaaccl_code =>
                    ACCL_next <= A_reg;
                    ACCH_next <= ACCH_reg;
                    state_next <= fetch_decode;
                when movbaccl_code =>
                    ACCL_next <= B_reg;
                    ACCH_next <= ACCH_reg;
                    state_next <= fetch_decode;
                when movaacch_code =>
                    ACCH_next <= A_reg;
                    ACCL_next <= ACCL_reg;
                    state_next <= fetch_decode;
                when movbacch_code =>
                    ACCH_next <= B_reg;
                    ACCL_next <= ACCL_reg;
                    state_next <= fetch_decode;
                when movaccla_code =>
                    A_next <= ACCL_reg;
                    state_next <= fetch_decode;
                when movacclb_code =>
                    B_next <= ACCL_reg;
                    state_next <= fetch_decode;
                when movaccha_code =>
                    A_next <= ACCH_reg;
                    state_next <= fetch_decode;
                when movacchb_code =>
                    B_next <= ACCH_reg;
                    state_next <= fetch_decode;
                when stospa_code =>
                    A_next <= x"00" & SP_reg;
                    state_next <= fetch_decode;
                when stospb_code =>
                    B_next <= x"00" & SP_reg;
                    state_next <= fetch_decode;
                when stouspa_code =>
                    A_next <= x"00" & USP_reg;
                    state_next <= fetch_decode;
                when stouspb_code =>
                    B_next <= x"00" & USP_reg;
                    state_next <= fetch_decode;
                when ldusp_code =>
                    USP_next <= SP_reg;
                    state_next <= fetch_decode;
                when lduspa_code =>
                    USP_next <= A_reg(7 downto 0);
                    state_next <= fetch_decode;
                when lduspb_code =>
                    USP_next <= B_reg(7 downto 0);
                    state_next <= fetch_decode;
                when lduspr_code =>
                    USP_next <= R_reg(7 downto 0);
                    state_next <= fetch_decode;
                when incusp_code =>
                    USP_next <= USP_reg + 1;
                    state_next <= fetch_decode;                
                when decusp_code =>
                    USP_next <= USP_reg - 1;
                    state_next <= fetch_decode;                
                when movka_code =>
                    state_next <= load_khx;
                when movkb_code =>
                    state_next <= load_khx;
                when movki_code =>
                    state_next <= load_khx;
                when movkj_code =>
                    state_next <= load_khx;
                when movkn_code =>
                    state_next <= load_khx;
                when movkm_code =>
                    state_next <= load_khx;
                when lduspk_code =>
                    state_next <= load_usp;     
                when movam_code =>           
                    state_next <= load_hi_movxm;
                when movbm_code =>           
                    state_next <= load_hi_movxm;
                when movrlm_code =>           
                    state_next <= load_hi_movxm;
                when movrhm_code =>           
                    state_next <= load_hi_movxm;
                when movma_code =>           
                    state_next <= load_hi_movmx;
                when movmb_code =>           
                    state_next <= load_hi_movmx;
                when incmpm_code =>           
                    state_next <= load_hi_movmx;
                when decmpm_code =>           
                    state_next <= load_hi_movmx;
                when movai_code =>
                    state_next <= load_hi_movi;
                when movbi_code =>
                    state_next <= load_hi_movi;
                when movrli_code =>
                    state_next <= load_hi_movi;
                when movrhi_code =>
                    state_next <= load_hi_movi;
                when movia_code =>
                    state_next <= load_hi_movi;
                when movib_code => 
                    state_next <= load_hi_movi;
                when movaipp_code =>
                    state_next <= load_hi_movi;
                when movbipp_code =>
                    state_next <= load_hi_movi;
                when movrlipp_code =>
                    state_next <= load_hi_movi;
                when movrhipp_code =>
                    state_next <= load_hi_movi;
                when movippa_code =>
                    state_next <= load_hi_movi;
                when movippb_code =>
                    state_next <= load_hi_movi;
                when movmmia_code =>
                    state_next <= load_hi_movi;
                when movmmib_code =>
                    state_next <= load_hi_movi;
                when movas_code =>
                    state_next <= movas_exe;
                when movbs_code =>
                    state_next <= movbs_exe;
                when movrls_code =>
                    state_next <= movrls_exe;
                when movrhs_code =>
                    state_next <= movrhs_exe;
                when movsa_code =>
                    state_next <= movsa_exe;
                when movsb_code =>
                    state_next <= movsb_exe;
                when uadd_code =>
                    WR33_next <= ("00000000000000000"&A_reg)+("00000000000000000"&B_reg);
                    state_next <= add_result;
                when sadd_code =>
                    if (A_reg(15)='0' and B_reg(15)='0') then
                        WR33_next <= ("00000000000000000"&A_reg)+("00000000000000000"&B_reg);
                    elsif (A_reg(15)='0' and B_reg(15)='1') then
                        WR33_next <= ("00000000000000000"&A_reg)+("11111111111111111"&B_reg);
                    elsif (A_reg(15)='1' and B_reg(15)='0') then
                        WR33_next <= ("11111111111111111"&A_reg)+("00000000000000000"&B_reg);
                    else
                        WR33_next <= ("11111111111111111"&A_reg)+("11111111111111111"&B_reg);
                    end if;
                    state_next <= add_result;
                when ac_code =>
                    WR33_next <= ('0'&R_reg)+('0'&ACC_reg);
                    state_next <= add_result;
                when umul_code =>
                    WR33_next <= (others=>'0');
                    CNT_next <= (others=>'0');
                    SR1_next <= "00000000000000000"&A_reg;
                    SR2_next <= "00000000000000000"&B_reg;
                    state_next <= xmul_exe;
                when smul_code =>
                    WR33_next <= (others=>'0');
                    CNT_next <= (others=>'0');
                    if A_reg(15)='0' then
                             SR1_next <= "00000000000000000"&A_reg;
                    else
                             SR1_next <= "11111111111111111"&A_reg;
                    end if;
                    if B_reg(15)='0' then
                             SR2_next <= "00000000000000000"&B_reg;
                    else
                             SR2_next <= "11111111111111111"&B_reg;
                    end if;
                    state_next <= xmul_exe;
                when umac_code =>
                    WR33_next <= (others=>'0');
                    CNT_next <= (others=>'0');
                    SR1_next <= "00000000000000000"&A_reg;
                    SR2_next <= "00000000000000000"&B_reg;
                    state_next <= xmul_exe;
                when smac_code =>
                    WR33_next <= (others=>'0');
                    CNT_next <= (others=>'0');
                    if A_reg(15)='0' then
                        SR1_next <= "00000000000000000"&A_reg;
                    else
                        SR1_next <= "11111111111111111"&A_reg;
                    end if;
                    if B_reg(15)='0' then
                        SR2_next <= "00000000000000000"&B_reg;
                    else
                        SR2_next <= "11111111111111111"&B_reg;
                    end if;
                    state_next <= xmul_exe;
                when sracc_code =>
                    WR33_next <= '0' & ACC_reg;
                    CNT_next <= A_reg(5 downto 0);
                    state_next <= sxacc_exe;
                when sraacc_code =>
                    WR33_next <= '0' & ACC_reg;
                    CNT_next <= A_reg(5 downto 0);
                    state_next <= sxacc_exe;
                when slacc_code =>
                    WR33_next <= '0' & ACC_reg;
                    CNT_next <= A_reg(5 downto 0);
                    state_next <= sxacc_exe;
                when nota_code =>
                    WR33_next <= "00000000000000000"& not A_reg;
                    state_next <= log_result;
                when notb_code =>
                    WR33_next <= "00000000000000000"& not B_reg;
                    state_next <= log_result;
                when and_code =>
                    WR33_next <= "00000000000000000"& (A_reg and B_reg);
                    state_next <= log_result;
                when or_code =>
                    WR33_next <= "00000000000000000"& (A_reg or B_reg);
                    state_next <= log_result;
                when xor_code =>
                    WR33_next <= "00000000000000000"& (A_reg xor B_reg);
                    state_next <= log_result;
                when cmpin_code =>
                    WR33_next <= ("00000000000000000"&I_reg)-("00000000000000000"&N_reg);
                    state_next <= cmp_result;
                when cmpjm_code =>
                    WR33_next <= ("00000000000000000"&J_reg)-("00000000000000000"&M_reg);
                    state_next <= cmp_result;
                when outa_code =>           
                    state_next <= load_ioadd;
                when ina_code =>           
                    state_next <= load_ioadd;
                when outk_code =>           
                    state_next <= load_iok;
                when others =>
                    state_next <= stop;
              end case;
            end if;

         when load_ha_jmp => 
            IP_next <= IP_reg + 1;
            H_next <= unsigned(code);
            state_next <= load_la_jmp;
         when load_la_jmp =>
            L_next <= unsigned(code);
            state_next <= load_ip;
         when load_ip =>
            IP_next <= H_reg(CODE_ADD_SIZE-CODE_SIZE-1 downto 0) & L_reg;
            state_next <= fetch_decode;
         when jz16_exe =>
               if F_Z16_reg='1' then
                   state_next <= load_ha_jmp;
               else
                  IP_next <= IP_reg + 2;
                  state_next <= fetch_decode;
               end if;
         when jz32_exe =>
               if F_Z32_reg='1' then
                   state_next <= load_ha_jmp;
               else
                   IP_next <= IP_reg + 2;
                   state_next <= fetch_decode;
               end if;
         when jn16_exe =>
               if F_N16_reg='1' then
                   state_next <= load_ha_jmp;
               else
                   IP_next <= IP_reg + 2;
                   state_next <= fetch_decode;
               end if;
         when jn32_exe =>
               if F_N32_reg='1' then
                    state_next <= load_ha_jmp;
               else
                    IP_next <= IP_reg + 2;
                    state_next <= fetch_decode;
               end if;
         when jo16_exe =>
               if F_O16_reg='1' then
                    state_next <= load_ha_jmp;
               else
                    IP_next <= IP_reg + 2;
                    state_next <= fetch_decode;
               end if;
         when jo32_exe =>
               if F_O32_reg='1' then
                    state_next <= load_ha_jmp;
               else
                    IP_next <= IP_reg + 2;
                    state_next <= fetch_decode;
               end if;
         when jco16_exe =>
               if F_CO16_reg='1' then
                    state_next <= load_ha_jmp;
               else
                    IP_next <= IP_reg + 2;
                    state_next <= fetch_decode;
               end if;
         when jco32_exe =>
               if F_CO32_reg='1' then
                    state_next <= load_ha_jmp;
               else
                    IP_next <= IP_reg + 2;
                    state_next <= fetch_decode;
               end if;
         when jnz16_exe =>
               if F_Z16_reg='0' then
                   state_next <= load_ha_jmp;
               else
                  IP_next <= IP_reg + 2;
                  state_next <= fetch_decode;
               end if;
         when jnz32_exe =>
               if F_Z32_reg='0' then
                   state_next <= load_ha_jmp;
               else
                   IP_next <= IP_reg + 2;
                   state_next <= fetch_decode;
               end if;
         when jp16_exe =>
               if F_N16_reg='0' then
                   state_next <= load_ha_jmp;
               else
                   IP_next <= IP_reg + 2;
                   state_next <= fetch_decode;
               end if;
         when jp32_exe =>
               if F_N32_reg='0' then
                    state_next <= load_ha_jmp;
               else
                    IP_next <= IP_reg + 2;
                    state_next <= fetch_decode;
               end if;
         when jno16_exe =>
               if F_O16_reg='0' then
                    state_next <= load_ha_jmp;
               else
                    IP_next <= IP_reg + 2;
                    state_next <= fetch_decode;
               end if;
         when jno32_exe =>
               if F_O32_reg='0' then
                    state_next <= load_ha_jmp;
               else
                    IP_next <= IP_reg + 2;
                    state_next <= fetch_decode;
               end if;
         when jnco16_exe =>
               if F_CO16_reg='0' then
                    state_next <= load_ha_jmp;
               else
                    IP_next <= IP_reg + 2;
                    state_next <= fetch_decode;
               end if;
         when jnco32_exe =>
               if F_CO32_reg='0' then
                    state_next <= load_ha_jmp;
               else
                    IP_next <= IP_reg + 2;
                    state_next <= fetch_decode;
               end if;
         when load_ha_call => 
               IP_next <= IP_reg + 1;
               H_next <= unsigned(code);
               state_next <= load_la_call;
         when load_la_call =>
               IP_next <= IP_reg + 1;
               L_next <= unsigned(code);
               state_next <= push_ip;
         when push_ip =>
               sout <= std_logic_vector("0000"&IP_reg);
               SP_next <= SP_reg + 1;
               state_next <= load_ip;
         when pop_ip_ini =>
               SP_next <= SP_reg - 1;
               state_next <= pop_ip;
         when pop_ip =>
               IP_next <=unsigned(sin(11 downto 0));
               state_next <= fetch_decode;
         when pusha_exe =>
               sout <= std_logic_vector(A_reg);
               SP_next <= SP_reg + 1;
               state_next <= fetch_decode;
         when pushb_exe =>
               sout <= std_logic_vector(B_reg);
               SP_next <= SP_reg + 1;
               state_next <= fetch_decode;
         when pushi_exe =>
               sout <= std_logic_vector(I_reg);
               SP_next <= SP_reg + 1;
               state_next <= fetch_decode;
         when pushj_exe =>
               sout <= std_logic_vector(J_reg);
               SP_next <= SP_reg + 1;
               state_next <= fetch_decode;
         when pushn_exe =>
               sout <= std_logic_vector(N_reg);
               SP_next <= SP_reg + 1;
               state_next <= fetch_decode;
         when pushm_exe =>
               sout <= std_logic_vector(M_reg);
               SP_next <= SP_reg + 1;
               state_next <= fetch_decode;
         when dec_spx =>
               SP_next <= SP_reg - 1;
               state_next <= point_spx;
         when point_spx =>
               case instruction_reg is
                    when popa_code =>
                        state_next <= popa_exe;
                    when popb_code =>
                        state_next <= popb_exe;
                    when popi_code =>
                        state_next <= popi_exe;
                    when popj_code =>
                        state_next <= popj_exe;
                    when popn_code =>
                        state_next <= popn_exe;
                    when others =>
                        state_next <= popm_exe;
               end case;
         when popa_exe =>
               A_next <= unsigned(sin);
               state_next <= fetch_decode;
         when popb_exe =>
               B_next <= unsigned(sin);
               state_next <= fetch_decode;
         when popi_exe =>
               I_next <= unsigned(sin);
               state_next <= fetch_decode;
         when popj_exe =>
               J_next <= unsigned(sin);
               state_next <= fetch_decode;
         when popn_exe =>
               N_next <= unsigned(sin);
               state_next <= fetch_decode;
         when popm_exe =>
               M_next <= unsigned(sin);
               state_next <= fetch_decode;
         when load_khx => 
               IP_next <= IP_reg + 1;
               H_next <= unsigned(code);
               state_next <= load_klx;
         when load_klx =>
               IP_next <= IP_reg + 1;
               L_next <= unsigned(code);
               case instruction_reg is
                    when movka_code =>
                        state_next <= store_ka;
                    when movkb_code =>
                        state_next <= store_kb;
                    when movki_code =>
                        state_next <= store_ki;
                    when movkj_code =>
                        state_next <= store_kj;
                    when movkn_code =>
                        state_next <= store_kn;
                    when others =>
                        state_next <= store_km;
               end case;
         when store_ka =>
               A_next <= H_reg & L_reg;
               state_next <= fetch_decode;
         when store_kb =>
               B_next <= H_reg & L_reg;
               state_next <= fetch_decode;
         when store_ki =>
               I_next <= H_reg & L_reg;
               state_next <= fetch_decode;
         when store_kj =>
               J_next <= H_reg & L_reg;
               state_next <= fetch_decode;
         when store_kn =>
               N_next <= H_reg & L_reg;
               state_next <= fetch_decode;
         when store_km =>
               M_next <= H_reg & L_reg;
               state_next <= fetch_decode;
         when load_usp =>
               IP_next <= IP_reg + 1;
               USP_next <= unsigned(code);
               state_next <= fetch_decode;
         when load_hi_movxm => 
               IP_next <= IP_reg + 1;
               H_next <= unsigned(code);
               state_next <= load_li_movxm;
         when load_li_movxm =>
               IP_next <= IP_reg + 1;
               L_next <= unsigned(code);
               state_next <= load_dp_movxm;
         when load_dp_movxm =>
               DP_next <= H_reg(DATA_ADD_SIZE-CODE_SIZE-1 downto 0) & L_reg;
               case instruction_reg is
                    when movam_code =>
                        state_next <= movam_exe;
                    when movbm_code =>
                        state_next <= movbm_exe;
                    when movrlm_code =>
                        state_next <= movrlm_exe;
                    when others =>
                        state_next <= movrhm_exe;
               end case;
         when  movam_exe =>
               dout <= std_logic_vector(A_reg);         
               state_next <= fetch_decode;
         when  movbm_exe =>
               dout <= std_logic_vector(B_reg);         
               state_next <= fetch_decode;
         when  movrlm_exe =>
               dout <= std_logic_vector(RL_reg);         
               state_next <= fetch_decode;
         when  movrhm_exe =>
               dout <= std_logic_vector(RH_reg);         
               state_next <= fetch_decode;
         when load_hi_movmx => 
               IP_next <= IP_reg + 1;
               H_next <= unsigned(code);
               state_next <= load_li_movmx;
         when load_li_movmx =>
               IP_next <= IP_reg + 1;
               L_next <= unsigned(code);
               state_next <= load_dp_movmx;
         when load_dp_movmx =>
               DP_next <= H_reg(DATA_ADD_SIZE-CODE_SIZE-1 downto 0) & L_reg;
               case instruction_reg is
                    when movma_code =>
                        state_next <= movma_exe;
                    when movmb_code =>
                        state_next <= movmb_exe;
                    when incmpm_code =>
                        state_next <= load_xpp;
                    when others =>
                        state_next <= load_xmm;
               end case;
         when movma_exe =>
              A_next <= unsigned(din);
              state_next <= fetch_decode;
         when movmb_exe =>
              B_next <= unsigned(din);
              state_next <= fetch_decode;
         when load_xpp =>
              X_next <= unsigned(din)+1;
              state_next <= movxrm;
         when load_xmm =>
              X_next <= unsigned(din)-1;
              state_next <= movxrm;
         when movxrm =>
              dout <= std_logic_vector(X_reg);         
              DP_next <= DP_reg + 1;
              state_next <= load_y;
         when load_y =>
              Y_next <= unsigned(din);
              state_next <= cmp_xy;
         when cmp_xy =>
               WR33_next <= ("00000000000000000"&X_reg)-("00000000000000000"&Y_reg);
               state_next <= cmp_result;
         when load_hi_movi => 
              IP_next <= IP_reg + 1;
              H_next <= unsigned(code);
              state_next <= load_li_movi;
         when load_li_movi =>
              IP_next <= IP_reg + 1;
              L_next <= unsigned(code);
              state_next <= load_dp_movi;
         when load_dp_movi =>
              DP_next <= H_reg(DATA_ADD_SIZE-CODE_SIZE-1 downto 0) & L_reg;
              DPB_next <= H_reg(DATA_ADD_SIZE-CODE_SIZE-1 downto 0) & L_reg;
              state_next <= load_ix;
         when load_ix =>
              DP_next <= unsigned(din(DATA_ADD_SIZE-1 downto 0));
              UDP_next <= unsigned(din(DATA_ADD_SIZE-1 downto 0));
              case instruction_reg is
                   when movai_code =>
                        state_next <= movam_exe;
                   when movbi_code =>
                        state_next <= movbm_exe;
                   when movrli_code =>
                        state_next <= movrlm_exe;
                   when movrhi_code =>
                        state_next <= movrhm_exe;
                   when movia_code =>
                        state_next <= movia_exe;
                   when movib_code =>
                        state_next <= movib_exe;
                   when movaipp_code =>
                        state_next <= movaipp_exe;
                   when movbipp_code =>
                        state_next <= movbipp_exe;
                   when movrlipp_code =>
                        state_next <= movrlipp_exe;
                   when movrhipp_code =>
                        state_next <= movrhipp_exe;
                   when movippa_code =>
                        state_next <= movippa_exe;
                   when movippb_code =>
                        state_next <= movippb_exe;
                   when movmmia_code =>
                         state_next <= ix_dec_a;
                   when others =>
                         state_next <= ix_dec_b;
              end case;
         when movia_exe =>
              A_next <= unsigned(din);
              state_next <= fetch_decode;
         when movib_exe =>
              B_next <= unsigned(din);
              state_next <= fetch_decode;
         when movaipp_exe =>
              dout <= std_logic_vector(A_reg);         
              state_next <= ix_inc;
         when movbipp_exe =>
              dout <= std_logic_vector(B_reg);         
              state_next <= ix_inc;
         when movrlipp_exe =>
              dout <= std_logic_vector(RL_reg);         
              state_next <= ix_inc;
         when movrhipp_exe =>
              dout <= std_logic_vector(RH_reg);         
              state_next <= ix_inc;
         when ix_inc =>
              UDP_next <= UDP_reg + 1;
              DP_next <= DPB_reg;
              state_next <= ix_sto;
         when ix_sto =>      
              dout <= std_logic_vector("00000"&UDP_reg);
              state_next <= fetch_decode;
         when movippa_exe =>
              A_next <= unsigned(din);
              state_next <= ix_inc;
         when movippb_exe =>
              B_next <= unsigned(din);
              state_next <= ix_inc;
         when ix_dec_a =>
              UDP_next <= UDP_reg - 1;
              DP_next <= DP_reg-1;
              state_next <= movmmia_exe;
         when movmmia_exe =>
              A_next <= unsigned(din);
              state_next <= ix_dest;
         when ix_dec_b =>
              UDP_next <= UDP_reg - 1;
              DP_next <= DP_reg-1;
              state_next <= movmmib_exe;
         when movmmib_exe =>
              B_next <= unsigned(din);
              state_next <= ix_dest;
         when ix_dest =>
              DP_next <= DPB_reg;
              state_next <= ix_sto;
         when movas_exe =>
              sout <= std_logic_vector(A_reg);
              state_next <= fetch_decode;
         when movbs_exe =>
              sout <= std_logic_vector(B_reg);
              state_next <= fetch_decode;
         when movrls_exe =>
              sout <= std_logic_vector(RL_reg);
              state_next <= fetch_decode;
         when movrhs_exe =>
              sout <= std_logic_vector(RH_reg);
              state_next <= fetch_decode;
         when movsa_exe =>
              A_next <= unsigned(sin);
              state_next <= fetch_decode;
         when movsb_exe =>
              B_next <= unsigned(sin);
              state_next <= fetch_decode;
         when add_result =>
              if WR33_reg(15 downto 0)=x"0000" then
                F_Z16_next <= '1';
              else
                F_Z16_next <= '0';
              end if;
              
              if(A_reg(15)='1' and B_reg(15)='1' and WR33_reg(15)='0') then
                F_CO16_next <= '1'; 
              elsif (A_reg(15)='0' and B_reg(15)='0' and WR33_reg(15)='1') then
                F_CO16_next <= '1';
              else
                F_CO16_next <= '0';
              end if;
                       
              F_N16_next <= WR33_reg(15);
              F_O16_next <= WR33_reg(16);
              
              if WR33_reg(31 downto 0)=x"00000000" then
                F_Z32_next <= '1';
              else
                F_Z32_next <= '0';
              end if;
              
              if(A_reg(15)='1' and B_reg(15)='1' and WR33_reg(31)='0') then
                F_CO32_next <= '1'; 
              elsif (A_reg(15)='0' and B_reg(15)='0' and WR33_reg(31)='1') then
                F_CO32_next <= '1';
              else
                F_CO32_next <= '0';
              end if;
                       
              F_N32_next <= WR33_reg(31);
              F_O32_next <= WR33_reg(32);

              if (instruction_reg=ac_code) or (instruction_reg=umac_code) or (instruction_reg=smac_code) then
                    ACC_next <= WR33_reg(31 downto 0);
              else 
                    R_next <= WR33_reg(31 downto 0);
              end if;
              
              state_next <= fetch_decode;
         when cmp_result =>
              if WR33_reg(15 downto 0)=x"0000" then
                F_Z16_next <= '1';
              else
                F_Z16_next <= '0';
              end if;
              
              F_CO16_next <= '0';
                       
              F_N16_next <= WR33_reg(15);
              F_O16_next <= WR33_reg(16);
              
              if WR33_reg(31 downto 0)=x"00000000" then
                F_Z32_next <= '1';
              else
                F_Z32_next <= '0';
              end if;
              
              F_CO32_next <= '0';
                       
              F_N32_next <= WR33_reg(31);
              F_O32_next <= WR33_reg(32);

              R_next <= WR33_reg(31 downto 0);
              
              state_next <= fetch_decode;
         when xmul_exe =>
              if CNT_REG < 16 then
                if SR2_reg(0)='1' then
                    if (instruction_reg= umul_code) or (instruction_reg= umac_code) then
                        WR33_next <= WR33_reg + SR1_reg;
                    else
                        if CNT_REG = 15 then
                            WR33_next <= WR33_reg + not(SR1_reg) + 1;
                        else
                            WR33_next <= WR33_reg + SR1_reg;
                        end if;
                    
                    end if;    
                end if;
                CNT_next <= CNT_reg + 1;
                SR1_next <= SR1_reg(31 downto 0) & '0'; 
                SR2_next <= '0' & SR2_reg(32 downto 1); 
                state_next <= xmul_exe;

              else
                if WR33_reg(15 downto 0)=x"0000" then
                    F_Z16_next <= '1';
                else
                    F_Z16_next <= '0';
                end if;
              
                if(A_reg(15)='1' and B_reg(15)='1' and WR33_reg(15)='1') then
                    F_CO16_next <= '1'; 
                elsif (A_reg(15)='0' and B_reg(15)='0' and WR33_reg(15)='1') then
                    F_CO16_next <= '1';
                else
                    F_CO16_next <= '0';
                end if;
                       
                F_N16_next <= WR33_reg(15);
                F_O16_next <= WR33_reg(16);
              
                if WR33_reg(31 downto 0)=x"00000000" then
                    F_Z32_next <= '1';
                else
                    F_Z32_next <= '0';
                end if;
              
                if(A_reg(15)='1' and B_reg(15)='1' and WR33_reg(31)='1') then
                    F_CO32_next <= '1'; 
                elsif (A_reg(15)='0' and B_reg(15)='0' and WR33_reg(31)='1') then
                    F_CO32_next <= '1';
                else
                    F_CO32_next <= '0';
                end if;
                       
                F_N32_next <= WR33_reg(31);
                F_O32_next <= WR33_reg(32);

                if (instruction_reg= umac_code) or (instruction_reg= smac_code) then
                    WR33_next <= WR33_reg+('0'&ACC_reg);
                    state_next <= add_result;
                else
                    R_next <= WR33_reg(31 downto 0);
                    state_next <= fetch_decode;
                end if;
              end if;            

         when sxacc_exe =>
              if CNT_REG = 0 then
                if WR33_reg(15 downto 0)=x"0000" then
                  F_Z16_next <= '1';
                else
                  F_Z16_next <= '0';
                end if;
      
                F_CO16_next <= '0';
               
                F_N16_next <= WR33_reg(15);
                F_O16_next <= WR33_reg(16);
      
                if WR33_reg(31 downto 0)=x"00000000" then
                  F_Z32_next <= '1';
                else
                  F_Z32_next <= '0';
                end if;
      
                F_CO32_next <= '0';
               
                F_N32_next <= WR33_reg(31);
                F_O32_next <= WR33_reg(32);

                R_next <= WR33_reg(31 downto 0);
                state_next <= fetch_decode;

              else
                if (instruction_reg = sracc_code) or (instruction_reg = sraacc_code) then
                    if instruction_reg = sracc_code then
                        WR33_next <= '0' & WR33_reg(32 downto 1);
                    else
                        if WR33_reg(31) = '1' then
                            WR33_next <= "11" & WR33_reg(31 downto 1);
                        else
                            WR33_next <= '0' & WR33_reg(32 downto 1);
                        end if;                    
                    end if;
                  else
                    WR33_next <= WR33_reg(31 downto 0) & '0';
                  end if;
              
                  CNT_next <= CNT_reg - 1;
                  state_next <= sxacc_exe;
              end if;            
             
         when log_result =>
              if WR33_reg(15 downto 0)=x"0000" then
                F_Z16_next <= '1';
                F_Z32_next <= '1';
              else
                F_Z16_next <= '0';
                F_Z32_next <= '0';
              end if;
       
              F_CO16_next <= '0';       
              F_N16_next <= '0';
              F_O16_next <= '0';
       
              F_CO32_next <= '0';       
              F_N32_next <= '0';
              F_O32_next <= '0';
         
              R_next <= WR33_reg(31 downto 0);
              state_next <= fetch_decode;         
         when load_ioadd => 
               IP_next <= IP_reg + 1;
               PP_next <= unsigned(code);
               case instruction_reg is
                    when outa_code =>
                        state_next <= outa_exe;
                    when others =>
                        state_next <= ina_exe;
               end case;
         when outa_exe =>
               io_o <= std_logic_vector(A_reg(7 downto 0));         
               state_next <= fetch_decode;
         when ina_exe =>
              A_next <= "00000000" & unsigned(io_i);
              state_next <= fetch_decode;
         when load_iok => 
               IP_next <= IP_reg + 1;
               H_next <= unsigned(code);
               state_next <= ld_ioadd4k;
         when ld_ioadd4k => 
               IP_next <= IP_reg + 1;
               PP_next <= unsigned(code);
               state_next <= outk_exe;
         when outk_exe =>
               io_o <= std_logic_vector(H_reg);         
               state_next <= fetch_decode;
         when ini_iss =>
               PP_next <= x"01";
               ISF_next <= '1';         
               state_next <= in_intx_F;
         when in_intx_F =>
               L_next <= unsigned(io_i);
               if int0 = '1' then
                     state_next <= set_int0_F;
               else
                     if int1 = '1' then
                        state_next <= set_int1_F;
                     else
                        state_next <= set_int2_F;
                     end if;                    
               end if;    
         when set_int0_F =>
               io_o <= std_logic_vector(L_reg or x"01");         
               state_next <= ld_iss_vec;
         when set_int1_F =>
               io_o <= std_logic_vector(L_reg or x"02");         
               state_next <= ld_iss_vec;
         when set_int2_F =>
               io_o <= std_logic_vector(L_reg or x"04");         
               state_next <= ld_iss_vec;
         when ld_iss_vec =>
               if int0 = '1' then
                  H_next <= INT0_VEC_ADD(15 downto 8);
                  L_next <= INT0_VEC_ADD(7 downto 0);
               else
                     if int1 = '1' then
                  H_next <= INT1_VEC_ADD(15 downto 8);
                  L_next <= INT1_VEC_ADD(7 downto 0);
                     else
                  H_next <= INT2_VEC_ADD(15 downto 8);
                  L_next <= INT2_VEC_ADD(7 downto 0);
                     end if;                    
               end if;    
                    
               if FDI_reg = '1' then
                     state_next <= push_ip_int;
               else
                     state_next <= load_ip;
               end if;    
         when push_ip_int =>
               sout <= std_logic_vector("0000"&(IP_reg-1));
               SP_next <= SP_reg + 1;
               state_next <= push_rl;
         when push_rl =>
               sout <= std_logic_vector(R_reg(15 downto 0));
               SP_next <= SP_reg + 1;
               state_next <= push_rh;
         when push_rh =>
               sout <= std_logic_vector(R_reg(31 downto 16));
               SP_next <= SP_reg + 1;
               state_next <= push_f;
         when push_f =>
               sout <= std_logic_vector("00000000"&F_reg);
               SP_next <= SP_reg + 1;
               state_next <= load_ip;
         when ini_reti =>
               ISF_next <= '0'; 
                    
               if FDI_reg = '1' then
                  FDI_next <= '0';
                  SP_next <= SP_reg-1;
                  state_next <= pop_f;
               else
                  state_next <= stop;
               end if;    
         when pop_f =>
               F_next <= sin(7 downto 0);
               state_next <= pop_rh_ini;
         when pop_rh_ini =>
               SP_next <= SP_reg - 1;
               state_next <= pop_rh;
         when pop_rh =>
               H_next <=unsigned(sin(15 downto 8));
               L_next <=unsigned(sin(7 downto 0));
               state_next <= pop_rl_ini;
         when pop_rl_ini =>
               SP_next <= SP_reg - 1;
               state_next <= pop_rl_nres;
         when pop_rl_nres =>
               R_next <= H_reg & L_reg & unsigned(sin);
               state_next <= pop_ip_ini;
         when others =>
              state_next <=stop;
      end case;
   end process;

   -- look-ahead output logic
  --Para las seniales deben mostrar el estado deseado justo al iniciar 
   process(state_next)
  begin
     ramwe_next <= '0';
     stkwe_next <= '0';
     iowe_next <= '0';
    
     case state_next is
        when push_ip =>
           stkwe_next <= '1';
        when pusha_exe =>
           stkwe_next <= '1';
        when pushb_exe =>
           stkwe_next <= '1';
        when pushi_exe =>
           stkwe_next <= '1';
        when pushj_exe =>
           stkwe_next <= '1';
        when pushn_exe =>
           stkwe_next <= '1';
        when pushm_exe =>
           stkwe_next <= '1';
        when movam_exe =>
           ramwe_next <= '1';
        when movbm_exe =>
           ramwe_next <= '1';
        when movxrm =>
           ramwe_next <= '1';
        when movrlm_exe =>
           ramwe_next <= '1';
        when movrhm_exe =>
           ramwe_next <= '1';
        when movaipp_exe =>
           ramwe_next <= '1';
        when movbipp_exe =>
           ramwe_next <= '1';
        when movrlipp_exe =>
           ramwe_next <= '1';
        when movrhipp_exe =>
           ramwe_next <= '1';
        when ix_sto =>
           ramwe_next <= '1';
        when movas_exe =>
           stkwe_next <= '1';
        when movbs_exe =>
           stkwe_next <= '1';
        when movrls_exe =>
           stkwe_next <= '1';
        when movrhs_exe =>
           stkwe_next <= '1';                         
        when outa_exe =>
           iowe_next <= '1';
        when outk_exe =>
           iowe_next <= '1';
        when set_int0_F =>
           iowe_next <= '1';
        when set_int1_F =>
           iowe_next <= '1';
        when set_int2_F =>
           iowe_next <= '1';
        when push_ip_int =>
           stkwe_next <= '1';
        when push_rl =>
           stkwe_next <= '1';
        when push_rh =>
           stkwe_next <= '1';
        when push_f =>
           stkwe_next <= '1';
        when others =>         
     end case;
  end process;

   --  outputs
   state <= state_reg;
   flags <= F_reg;
   code_add <= std_logic_vector(IP_reg);
   data_add <= std_logic_vector(DP_reg);
   data_we <= ramwe_reg;

   with state_reg select
    stk_add <=  std_logic_vector(USP_reg) when movas_exe,   
                std_logic_vector(USP_reg) when movbs_exe,   
                std_logic_vector(USP_reg) when movrls_exe,   
                std_logic_vector(USP_reg) when movrhs_exe,   
                std_logic_vector(USP_reg) when movsa_exe,   
                std_logic_vector(USP_reg) when movsb_exe,   
                std_logic_vector(SP_reg) when others;   

   stk_we <= stkwe_reg;

   io_add <= std_logic_vector(PP_reg);
   io_we <= iowe_reg;

   r_out <= std_logic_vector(R_reg);

end my_arch;
