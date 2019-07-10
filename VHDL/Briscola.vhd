library ieee;
library briscola_package;
library briscola_lisci_package;
library briscola_situazioniNoLisci_package;
library briscola_fase2_package;
library briscola_penultimo_turno_package;
library briscola_utility_package;

use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use briscola_package.briscola_package.all;
use briscola_lisci_package.briscola_lisci_package.all;
use briscola_situazioniNoLisci_package.briscola_situazioniNoLisci_package.all;
use briscola_fase2_package.briscola_fase2_package.all;
use briscola_penultimo_turno_package.briscola_penultimo_turno_package.all;
use briscola_utility_package.briscola_utility_package.all;

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
		
		UART_TXD	: out std_logic
	);
end entity;

architecture Behaviour of Briscola is
	
	component Briscola_Datapath is 
	port (
		CLOCK					: in std_logic;
		RESET		       	: in std_logic;
		
		RX_LINE				: in std_logic;
		LCD0					: out std_logic_vector(0 to 6);
		LCD3					: out std_logic_vector(0 to 6);
		LCD1					: out std_logic_vector(0 to 6);
		LEDGREEN				: out std_logic_vector(0 to 7);
		
		DECIDI_CARTA		: in std_logic;
		INVIA_RISULTATO 	: in std_logic;
		NUOVO_TURNO			: in std_logic;
		PENULTIMO_TURNO	: in std_logic;
		
		TASTO_PREMUTO		: in std_logic; -- KEY(0) da collegare con
		
		MANO_RICEVUTA		: out std_logic;
		TOKEN_CPU			: out std_logic;
		PRESA_CPU			: out std_logic;
		VALUTA_PRESA		: out std_logic;
		
		TX_LINE 				: out std_logic -- UART_TXD da collegare con 
	);
	end component;
	
	component Briscola_Controller is
	port (
		CLOCK					: in std_logic;
		RESET					: in std_logic;
		
		LEDRED				: out std_logic_vector(0 to 9);
		LCD_STATO			: out std_logic_vector(0 to 6);
		TASTO_PIGIATO		: in std_logic; 
		
		MANO_RICEVUTA		: in std_logic;
		TOKEN_CPU			: in std_logic;
		PRESA_CPU			: in std_logic;
		VALUTA_PRESA		: in std_logic;
		
		DECIDI_CARTA		: out std_logic;
		INVIA_RISULTATO 	: out std_logic;
		NUOVO_TURNO			: out std_logic;
		PENULTIMO_TURNO		: out std_logic
	);
	end component;
	
	signal mano_ricevuta_cpu	: std_logic;
	signal token_ricevuto_cpu	: std_logic;
	signal cpu_presa			: std_logic;
	signal calcola_presa		: std_logic;
	signal decidi_carta_cpu		: std_logic;
	signal invia_punti			: std_logic;
	signal turno_nuovo			: std_logic;
	signal turno_penultimo		: std_logic;
	
begin
	controller : Briscola_Controller 
							port map(
								CLOCK => CLOCK_50,
								RESET => SW(9), 
								
								LEDRED => LEDR,		
								LCD_STATO => HEX2,
								TASTO_PIGIATO => NOT KEY(1),

								MANO_RICEVUTA => mano_ricevuta_cpu, 
								TOKEN_CPU => token_ricevuto_cpu, 
								PRESA_CPU => cpu_presa, 
								VALUTA_PRESA => calcola_presa, 
								
								DECIDI_CARTA => decidi_carta_cpu, 
								INVIA_RISULTATO => invia_punti, 
								NUOVO_TURNO => turno_nuovo,
								PENULTIMO_TURNO => turno_penultimo
							); 
	
	datapath : Briscola_Datapath 	
							port map(
								CLOCK => CLOCK_50, 
								RESET	=> SW(9), 
								
								RX_LINE => UART_RXD, 
								LCD0 => HEX0,
								LCD3 => HEX3,
								LCD1 => HEX1,
								LEDGREEN => LEDG,
																	
								DECIDI_CARTA => decidi_carta_cpu, 
								INVIA_RISULTATO => invia_punti, 
								NUOVO_TURNO => turno_nuovo,
								PENULTIMO_TURNO => turno_penultimo,
								
								TASTO_PREMUTO => NOT KEY(1), 
								
								MANO_RICEVUTA => mano_ricevuta_cpu, 
								TOKEN_CPU => token_ricevuto_cpu, 
								PRESA_CPU => cpu_presa, 
								VALUTA_PRESA => calcola_presa, 
								
								TX_LINE => UART_TXD
							);
		
end architecture;
