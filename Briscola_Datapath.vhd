library ieee;
library briscola_package;
library briscola_datapath_package;
library briscola_situazioniNoLisci_package;
library briscola_fase2_package;
library briscola_lisci_package;
library briscola_utility_package;
library briscola_penultimo_turno_package;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use briscola_package.briscola_package.all;
use briscola_datapath_package.briscola_datapath_package.all;
use briscola_situazioniNoLisci_package.briscola_situazioniNoLisci_package.all;
use briscola_lisci_package.briscola_lisci_package.all;
use briscola_fase2_package.briscola_fase2_package.all;
use briscola_utility_package.briscola_utility_package.all;
use briscola_penultimo_turno_package.briscola_penultimo_turno_package.all;

entity Briscola_Datapath is
	port (
		CLOCK				: in std_logic;
		RESET		      	: in std_logic;

		RX_LINE				: in std_logic;
		LCD0				: out std_logic_vector(0 to 6);
		LCD3				: out std_logic_vector(0 to 6);
		LCD1				: out std_logic_vector(0 to 6);
		LEDGREEN			: out std_logic_vector(0 to 7);
		
		DECIDI_CARTA		: in std_logic;
		INVIA_RISULTATO 	: in std_logic;
		NUOVO_TURNO			: in std_logic;
		PENULTIMO_TURNO		: in std_logic;
		
		TASTO_PREMUTO		: in std_logic; -- KEY(0) da collegare con
		
		MANO_RICEVUTA		: out std_logic;
		TOKEN_CPU			: out std_logic;
		PRESA_CPU			: out std_logic;
		VALUTA_PRESA		: out std_logic;
		
		TX_LINE 			: out std_logic -- UART_TXD da collegare con 
	);
end entity;

architecture RTL of Briscola_Datapath is
	signal punti_cpu								: integer;
	signal punti_player 							: integer;
	signal mano										: mano_cpu;
	signal briscola_partita						: carta;
	signal carta_giocata_pl						: carta;
	signal carta_giocata_cpu 					: carta;
	signal AZZERA_CARTE_GIOCATE				: std_logic;
	signal ASSEGNA_CARTA_GIOCATA_CPU			: std_logic;
	signal ASSEGNA_CARTA_GIOCATA_PLAYER		: std_logic;
	signal ASSEGNA_DATA_TRASMITTED_CARTA	: std_logic;
	signal ASSEGNA_DATA_TRASMITTED_TOKEN	: std_logic;
	signal sig_carta_da_lanciare_cpu			: carta;
	signal sig_carta_giocata_pl				: carta;
	
	signal data_transmitted 		: std_logic_vector(0 to 7);
	signal data_transmitted_carta 	: std_logic_vector(0 to 7);
	signal data_transmitted_token 	: std_logic_vector(0 to 7);
	signal data_valid_RX 			: std_logic; 
	signal data_received			: std_logic_vector(0 to 7);
	signal TX_ENABLE_CARTA			: std_logic; 
	signal TX_ENABLE_TOKEN			: std_logic;
	signal R_ENABLE					: std_logic;
	
	-- componenti
	component UART_RX 
	port (
		i_Clk       : in  std_logic;
		i_RX_Serial : in  std_logic;
			
		o_RX_DV     : out std_logic;
		o_RX_Byte   : out std_logic_vector(0 to 7)
	);
	end component;
	
begin 
--	LEDGREEN(4) <= TASTO_PREMUTO;
--	LEDGREEN(3) <= DECIDI_CARTA;
--	LEDGREEN(2) <= INVIA_RISULTATO;
--	LEDGREEN(1) <= NUOVO_TURNO;
--	LEDGREEN(0) <= PENULTIMO_TURNO;
		
	rx : UART_RX port map(CLOCK, RX_LINE, data_valid_RX, data_received);

	--
	NuovoTurno : process(CLOCK, RESET, NUOVO_TURNO) is
	begin
		if(rising_edge(CLOCK)) then
			if(NUOVO_TURNO = '1') then 
				AZZERA_CARTE_GIOCATE <= '1';
			end if;
		end if;
	
	end process;
	
	RiceviMano: process(CLOCK, RESET)
		variable mano_counter	: integer := 0;
		variable carta_ricevuta	: carta;
		variable briscola 		: boolean;
		variable seme_carta 		: seme; 
		variable numero 			: integer;
		variable valore			: integer;
		variable carta_reset 	: carta := (0, DENARI, 0, false);
	begin
		LCD0 <= numberTo7SegmentDisplay(mano_counter);
		
		if(RESET = '1') then
			for i in 0 to 2 loop 
				mano(i) <= carta_reset;
			end loop;
			
		elsif(rising_edge(CLOCK)) then			
			if(data_valid_RX = '1') then
				if(vectorIsNotZero(data_received)) then
					R_ENABLE <= '1';
				else
					R_ENABLE <= '0';
				end if;
			end if;
			
			if(R_ENABLE = '1') then
				if(data_received(7) = '1') then -- è una carta
					
					if(data_received(0) = '0') then
						briscola := false;
					else
						briscola := true;
					end if;
					
					case data_received(1 to 2) is 
						when "00" => 	
							seme_carta := BASTONI;
						when "10" =>	
							seme_carta := DENARI;
						when "01" => 	
							seme_carta := COPPE;
						when "11" =>	
							seme_carta := SPADE;
					end case;
					
					numero := to_integer(unsigned(reverse_vector(data_received(3 to 6))));
					valore := getValorefromNumber(numero);
				
					carta_ricevuta := (numero, seme_carta, valore, briscola);
					if(mano_counter = 3) then 
						briscola_partita <= carta_ricevuta;		
					elsif(mano_counter < 3) then
						mano(mano_counter) <= carta_ricevuta;
					else
						sig_carta_giocata_pl <= carta_ricevuta;
						ASSEGNA_CARTA_GIOCATA_PLAYER <= '1';
					end if;
		
					mano_counter := mano_counter + 1;
				
					R_ENABLE <= '0';
					if(mano_counter = 4) then
						MANO_RICEVUTA <= '1';
					else 
						MANO_RICEVUTA <= '0';
					end if;	
	
				elsif(data_received(7) = '0') then -- è un token 
					case data_received(4 to 6) is
						when "111" => 
							TOKEN_CPU <= '1';
						when "000" =>
							TOKEN_CPU <= '0';
						when others => 
					end case;
				end if;
				
			end if;
		end if;
	end process;
	
	CardManagement : process(CLOCK, AZZERA_CARTE_GIOCATE, ASSEGNA_CARTA_GIOCATA_CPU, ASSEGNA_CARTA_GIOCATA_PLAYER, 
									ASSEGNA_DATA_TRASMITTED_CARTA, ASSEGNA_DATA_TRASMITTED_TOKEN) is
		variable carta_reset : carta := (0, DENARI, 0, false);		-- questo process di supporto morale si occupa di assegnare i valori ai registri delle carte
	begin															-- perchè non è possibile assegnare un valore agli stessi registri in process diversi
		if(rising_edge(CLOCK)) then
			if(AZZERA_CARTE_GIOCATE = '1') then
				carta_giocata_cpu <= carta_reset;
				carta_giocata_pl <= carta_reset;
			elsif(ASSEGNA_CARTA_GIOCATA_CPU = '1') then
				carta_giocata_cpu <= sig_carta_da_lanciare_cpu;
			elsif(ASSEGNA_CARTA_GIOCATA_PLAYER = '1') then
				carta_giocata_pl <= sig_carta_giocata_pl;
			end if;
		end if;
	
	end process;
	
	--
	DecidiCarta : process(CLOCK, RESET, DECIDI_CARTA, PENULTIMO_TURNO) is 
		variable carta_reset 		: carta := (0, DENARI, 0, false);
		variable carta_da_lanciare 	: carta;
		variable num_carichi 		: integer := 0;
		variable num_briscole 		: integer := 0;
		variable indice 			: integer := 0;
		
	begin
		if(rising_edge(CLOCK)) then
	
		if(DECIDI_CARTA = '1') then 
				if(PENULTIMO_TURNO = '0') then
					if(carta_giocata_pl.numero = 0) then 
						if(isLiscio(mano)) then 
							indice := getCartaLiscia(mano);
						else 
							num_briscole := getNumeroBriscole(mano);
							num_carichi := getNumeroCarichi(mano);
							indice := determinaSituazioneNoLisci(num_carichi, num_briscole, mano);
						end if; --IS LISCIO
					else
						indice := decidiCartaFase2(mano, carta_giocata_pl);
					end if; -- FASE 1 o FASE 2
				else -- PENULTIMO_TURNO = 1 
					indice := decidiPenultimo(mano, briscola_partita);				
				end if; -- GIOCATA NORMALE
				
				carta_da_lanciare := mano(indice);
				sig_carta_da_lanciare_cpu <= carta_da_lanciare;
				LCD3 <= numberTo7SegmentDisplay(carta_da_lanciare.numero);
				LCD1 <= numberTo7SegmentDisplay(sig_carta_giocata_pl.numero);
				ASSEGNA_CARTA_GIOCATA_CPU <= '1';
				data_transmitted_carta <= fromCartaToByte(carta_da_lanciare);
				TX_ENABLE_CARTA <= TASTO_PREMUTO;
				-- ASSEGNA_DATA_TRASMITTED_CARTA <= '1';
				--LEDGREEN <= data_transmitted_carta;
				if((carta_da_lanciare.numero > 0) AND (sig_carta_giocata_pl.numero > 0)) then
					VALUTA_PRESA <= '1';
				else 
					VALUTA_PRESA <= '0';
				end if;
				
			else
				ASSEGNA_CARTA_GIOCATA_CPU <= '0';
				--ASSEGNA_DATA_TRASMITTED_CARTA <= '0';
			end if; -- DECIDI CARTA
		end if;
	end process;
	
	--ValutaPuntiPresa : process(CLOCK, FINE_MANO) is	
	ValutaeInviaRisultato : process(CLOCK, INVIA_RISULTATO) is
		variable carta_reset 	: carta := (0, DENARI, 0, false);
		variable risultato 		: boolean;
		variable byte_result		: std_logic_vector (0 to 7);
		variable byte_sent 		: boolean := false;
		
	begin 
		if(rising_edge(CLOCK)) then
			if(INVIA_RISULTATO = '1') then 
				if((sig_carta_da_lanciare_cpu.numero > 0) AND (sig_carta_giocata_pl.numero > 0)) then 
					risultato := valutaPresa(carta_giocata_cpu, carta_giocata_pl);
					if(risultato) then 
						punti_cpu <= punti_cpu + carta_giocata_cpu.valore + carta_giocata_pl.valore;
						byte_result := "00001111"; -- non tocca al giocatore, ha preso la CPU
					else
						punti_player <= punti_player + carta_giocata_cpu.valore + carta_giocata_pl.valore;
						byte_result := "01110000"; -- tocca al giocatore, ha preso il giocatore
					end if;

					if(byte_sent) then 
						--TX_ENABLE_TOKEN <= '0';
					else 
						data_transmitted_token <= reverse_vector(byte_result);
						--ASSEGNA_DATA_TRASMITTED_TOKEN <= '1';
						TX_ENABLE_TOKEN <= INVIA_RISULTATO;
						byte_sent := true;		
					end if;
				--else 
					--ASSEGNA_DATA_TRASMITTED_TOKEN <= '0';
				end if;
			end if;
		end if;
	
	end process;
	
	--LEDGREEN <= data_transmitted_token;
	
--	LEDGREEN(7) <= TX_ENABLE_CARTA;			
--	LEDGREEN(6) <= TX_ENABLE_TOKEN;
	LEDGREEN <= data_transmitted_token;
	
	InviaByte : process(CLOCK, TX_ENABLE_CARTA, TX_ENABLE_TOKEN) is
		-- Variabili per la trasmissione
		variable count 				: integer range 0 to 5207 	:= 5207; 	--9600 baud generator variable (50MHz/9600)
		variable bit_number 			: integer range 0 to 10 	:= 0;  		--start bit+8 data bits+stop bit
		variable count_tk 			: integer range 0 to 5207 	:= 5207; 	--9600 baud generator variable (50MHz/9600)
		variable bit_number_tk		: integer range 0 to 10 	:= 0;  		--start bit+8 data bits+stop bit
		variable byte_not_sent 		: boolean 						:= true;
		variable byte_not_sent_tk 	: boolean 						:= true;
		variable card_sent			: boolean						:= false;
	begin
		if(rising_edge(CLOCK)) then
			if(TX_ENABLE_CARTA = '1' AND TASTO_PREMUTO = '1') then
				if (count = 5207 AND byte_not_sent) then
					if (bit_number = 0) then
						TX_LINE <= '0'; --start bit
					elsif(bit_number = 9) then	
						TX_LINE <= '1'; -- stop bit
					elsif((bit_number > 0) and (bit_number < 9))  then
						TX_LINE <= data_transmitted_carta(bit_number-1); --8 data bits
					end if;
					bit_number := bit_number + 1;
					if(bit_number = 10) then --resetting the bit number
						byte_not_sent := false;
						bit_number := 0;
						card_sent := true;
					end if;
				end if;
					
				count := count + 1;
				if (count = 5208) then --resetting the baud generator counter
					count := 0;
				end if;
			else 
				byte_not_sent := true;
			end if;
			
			if(TX_ENABLE_TOKEN = '1' AND TASTO_PREMUTO = '1') then 
				if (count_tk = 5207 AND byte_not_sent_tk) then
					if(card_sent) then 
						if (bit_number_tk = 0) then
							TX_LINE <= '0'; --start bit
						elsif(bit_number_tk = 9) then	
							TX_LINE <= '1'; -- stop bit
						elsif((bit_number_tk > 0) and (bit_number_tk < 9))  then
							TX_LINE <= data_transmitted_token(bit_number_tk-1); --8 data bits
						end if;
					
						bit_number_tk := bit_number_tk + 1;
						if(bit_number_tk = 10) then --resetting the bit number
							byte_not_sent_tk := false;
							bit_number_tk := 0;
							card_sent := false;
						end if;
					end if;
				end if;
				
				count_tk := count_tk + 1;
				if (count_tk = 5208) then --resetting the baud generator counter
					count_tk := 0;
				end if;
			else
				byte_not_sent_tk := true;
			end if;
		end if;
			
	end process;
	
end architecture;