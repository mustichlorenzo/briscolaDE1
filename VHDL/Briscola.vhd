library ieee;
library briscola_package;
library briscola_lisci_package;
library briscola_situazioniNoLisci_package;
library briscola_fase2_package;
library briscola_penultimo_turno_package;
library briscola_utility_package;
library briscola_audio_package;

use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use briscola_package.briscola_package.all;
use briscola_lisci_package.briscola_lisci_package.all;
use briscola_situazioniNoLisci_package.briscola_situazioniNoLisci_package.all;
use briscola_fase2_package.briscola_fase2_package.all;
use briscola_penultimo_turno_package.briscola_penultimo_turno_package.all;
use briscola_utility_package.briscola_utility_package.all;
use briscola_audio_package.briscola_audio_package.all;

entity Briscola is 
	port ( 
		CLOCK_50 : in std_logic;
		SW 		: in std_logic_vector(0 to 9);
		UART_RXD	: in std_logic;
		KEY		: in std_logic_vector(0 to 3);
					
		HEX0 		: out std_logic_vector(0 to 6);
		HEX1 		: out std_logic_vector(0 to 6);
		HEX2 		: out std_logic_vector(0 to 6);
		HEX3 		: out std_logic_vector(0 to 6);
		
		LEDR 		: out std_logic_vector(0 to 9);
		LEDG		: out std_logic_vector(0 to 7);
		
		UART_TXD	: out std_logic;
		
		----------WM8731 pins-----
		AUD_BCLK		: out std_logic;
		AUD_XCK		: out std_logic;
		AUD_DACLRCK	: out std_logic;
		AUD_DACDAT	: out std_logic;
		
		----------I2C pins-----
		I2C_SCLK		: out std_logic;
		I2C_SDAT		: inout std_logic;
		
		---------FLASH pins-----
		FL_ADDR 		: out std_logic_vector(21 downto 0);
		FL_DQ 			: in std_logic_vector(7 downto 0);
		FL_OE_N 		: out std_logic;
		FL_RST_N 		: out std_logic;
		FL_WE_N 		: out std_logic
	);
end entity;

architecture Behaviour of Briscola is
	
	component Briscola_Datapath is 
	port (
		CLOCK					: in std_logic;
		RESET		       	: in std_logic;
		
		RX_LINE				: in std_logic;
--		LCD0					: out std_logic_vector(0 to 6);
		LCD3					: out std_logic_vector(0 to 6);
		LCD1					: out std_logic_vector(0 to 6);
		LEDGREEN				: out std_logic_vector(0 to 7);
		
		DECIDI_CARTA		: in std_logic;
		INVIA_RISULTATO 	: in std_logic;
		INVIA_RISULTATO_FINALE : in std_logic;
		NUOVO_TURNO			: in std_logic;
		PENULTIMO_TURNO	: in std_logic;
		
		TASTO_PREMUTO		: in std_logic; -- KEY(0) da collegare con
		TASTO_INIZIO		: in std_logic; -- KEY(3) per l'inizio della partita
		
		MANO_RICEVUTA		: out std_logic;
		TOKEN_CPU			: out std_logic;
		PRESA_CPU			: out std_logic;
		VALUTA_PRESA		: out std_logic;
		
		TX_LINE 				: out std_logic -- UART_TXD
	);
	end component;
	
	component Briscola_Controller is
	port (
		CLOCK				: in std_logic;
		RESET				: in std_logic;
		
		LEDRED				: out std_logic_vector(0 to 9);
		LCD_STATO			: out std_logic_vector(0 to 6);
		LCD_TURNO			: out std_logic_vector(0 to 6);
		TASTO_PIGIATO		: in std_logic; 
		
		MANO_RICEVUTA		: in std_logic;
		TOKEN_CPU			: in std_logic;
		PRESA_CPU			: in std_logic;
		VALUTA_PRESA		: in std_logic;
		
		DECIDI_CARTA		: out std_logic;
		INVIA_RISULTATO 	: out std_logic;
		INVIA_RISULTATO_FINALE : out std_logic;
		NUOVO_TURNO			: out std_logic;
		PENULTIMO_TURNO		: out std_logic
	);
	end component;
	
	component BriscolaAudio is 
	port (
		CLOCK_AUDIO	: in std_logic;
		RESET			: in std_logic;
		
		----------WM8731 pins-----
		AUD_BCLK		: out std_logic;
		AUD_XCK		: out std_logic;
		AUD_DACLRCK	: out std_logic;
		AUD_DACDAT	: out std_logic;
		
		----------I2C pins-----
		I2C_SCLK		: out std_logic;
		I2C_SDAT		: inout std_logic;
		
		---------FLASH pins-----
		FL_ADDR 		: out std_logic_vector(21 downto 0);
		FL_DQ 		: in std_logic_vector(7 downto 0);
		FL_OE_N 		: out std_logic;
		FL_RST_N 	: out std_logic;
		FL_WE_N 		: out std_logic
	);
	end component;
	
	component PLL is 
		port(
			inclk0	: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			c1		: OUT STD_LOGIC 
		);
	end component;
	
	signal mano_ricevuta_cpu	: std_logic;
	signal token_ricevuto_cpu	: std_logic;
	signal cpu_presa			: std_logic;
	signal calcola_presa		: std_logic;
	signal decidi_carta_cpu		: std_logic;
	signal invia_punti			: std_logic;
	signal invia_punti_finale	: std_logic;
	signal turno_nuovo			: std_logic;
	signal turno_penultimo		: std_logic;
	
	signal clock		: std_logic;
	signal clockAudio	: std_logic;
	
	signal RESET		: std_logic;
	signal reset_sync_reg	: std_logic;
	
begin
	controller : Briscola_Controller 
							port map(
								CLOCK => CLOCK_50,
								RESET => SW(9), 
								
								LEDRED => LEDR,		
								LCD_STATO => HEX2,
								LCD_TURNO => HEX0,
								TASTO_PIGIATO => NOT KEY(1),

								MANO_RICEVUTA => mano_ricevuta_cpu, 
								TOKEN_CPU => token_ricevuto_cpu, 
								PRESA_CPU => cpu_presa, 
								VALUTA_PRESA => calcola_presa, 
								
								DECIDI_CARTA => decidi_carta_cpu, 
								INVIA_RISULTATO => invia_punti, 
								INVIA_RISULTATO_FINALE => invia_punti_finale, 
								NUOVO_TURNO => turno_nuovo,
								PENULTIMO_TURNO => turno_penultimo
							); 
	
	datapath : Briscola_Datapath 	
							port map(
								CLOCK => CLOCK_50, 
								RESET => SW(9), 
								
								RX_LINE => UART_RXD, 
--								LCD0 => HEX0,
								LCD3 => HEX3,
								LCD1 => HEX1,
								LEDGREEN => LEDG,
																	
								DECIDI_CARTA => decidi_carta_cpu, 
								INVIA_RISULTATO => invia_punti,
								INVIA_RISULTATO_FINALE => invia_punti_finale,
								NUOVO_TURNO => turno_nuovo,
								PENULTIMO_TURNO => turno_penultimo,
								
								TASTO_PREMUTO => NOT KEY(1),
								TASTO_INIZIO => NOT KEY(3),
								
								MANO_RICEVUTA => mano_ricevuta_cpu, 
								TOKEN_CPU => token_ricevuto_cpu, 
								PRESA_CPU => cpu_presa, 
								VALUTA_PRESA => calcola_presa, 
								
								TX_LINE => UART_TXD
							);

	audio : BriscolaAudio
		port map(
			CLOCK_AUDIO	=> clockAudio,
			RESET			=> RESET,
			
			----------WM8731 pins-----
			AUD_BCLK		=> AUD_BCLK,
			AUD_XCK		=> AUD_XCK,
			AUD_DACLRCK	=> AUD_DACLRCK,
			AUD_DACDAT	=> AUD_DACDAT,
			
			----------I2C pins-----
			I2C_SCLK		=> I2C_SCLK,
			I2C_SDAT		=> I2C_SDAT,
			
			--------flash pins-------
			FL_ADDR 		=> FL_ADDR,
			FL_DQ 		=> FL_DQ,
			FL_OE_N 		=> FL_OE_N,
			FL_RST_N 	=> FL_RST_N,
			FL_WE_N 		=> FL_WE_N		
		);
		
		briscola_pll : PLL
		port map 
		(
			inclk0		=> CLOCK_50,
			c0			=> clock,		
			c1			=> clockAudio
		);
		
		reset_sync: process(CLOCK_50)
		begin
			if(rising_edge(CLOCK_50)) then
				reset_sync_reg <= SW(7);
				RESET <= reset_sync_reg;
			end if;
		end process;
		
end architecture;
