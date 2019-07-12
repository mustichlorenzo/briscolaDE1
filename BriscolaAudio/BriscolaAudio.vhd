library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity BriscolaAudio is
	port(
		CLOCK_50		: in std_logic;
		SW				: in std_logic_vector(0 to 9);
		
		--CODEC WM8731
		AUD_BCLK: out std_logic;
		AUD_XCK: out std_logic;
		AUD_DACLRCK: out std_logic;
		AUD_DACDAT: out std_logic;
		I2C_SCLK: out std_logic;
		I2C_SDAT: inout std_logic;
		
		--FLASH
		FL_ADDR : out std_logic_vector(21 downto 0);
		FL_DQ : in std_logic_vector(7 downto 0);
		FL_OE_N : out std_logic;
		FL_RST_N : out std_logic;
		FL_WE_N : out std_logic	
	);
end;

architecture RTL of BriscolaAudio is

	signal clock		: std_logic;
	signal clockAUDIO	: std_logic;
	
	signal RESET		: std_logic;
	
	--reset
	signal reset_sync_reg	:	std_logic;
	
begin

	audio : entity work.briscola_audio
		port map(
			clockAUDIO	=> clockAUDIO,
			RESET		=> RESET,
			
			----------WM8731 pins-----
			AUD_BCLK		=> AUD_BCLK,
			AUD_XCK		=> AUD_XCK,
			AUD_DACLRCK	=> AUD_DACLRCK,
			AUD_DACDAT	=> AUD_DACDAT,
			
			----------I2C pins-----
			I2C_SCLK		=> I2C_SCLK,
			I2C_SDAT		=> I2C_SDAT,
			
			--------flash pins-------
			FL_ADDR => FL_ADDR,
			FL_DQ => FL_DQ,
			FL_OE_N => FL_OE_N,
			FL_RST_N => FL_RST_N,
			FL_WE_N => FL_WE_N		
		);
		
	pll : entity work.PLL
		port map 
		(
			inclk0		=> CLOCK_50,
			c0				=> clock,		
			c1				=> clockAUDIO
		);
	
	reset_sync : process(CLOCK_50)
	begin
		if (rising_edge(CLOCK_50)) then
			reset_sync_reg <= SW(9);
			RESET <= reset_sync_reg;
		end if;
	end process;
	
end architecture;