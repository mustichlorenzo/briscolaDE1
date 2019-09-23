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
--		LCD0				: out std_logic_vector(0 to 6);
		LCD3				: out std_logic_vector(0 to 6);
		LCD1				: out std_logic_vector(0 to 6);
		LEDGREEN			: out std_logic_vector(0 to 7);
		
		DECIDI_CARTA		: in std_logic;
		INVIA_RISULTATO 	: in std_logic;
		INVIA_RISULTATO_FINALE 	: in std_logic;
		NUOVO_TURNO			: in std_logic;
		PENULTIMO_TURNO		: in std_logic;
		
		TASTO_PREMUTO		: in std_logic; -- KEY(1) da collegare con
		TASTO_INIZIO		: in std_logic;	-- KEY(3) per l'inizio della partita
		
		MANO_RICEVUTA		: out std_logic;
		TOKEN_CPU			: out std_logic;
		PRESA_CPU			: out std_logic;
		VALUTA_PRESA		: out std_logic;
		
		TX_LINE 			: out std_logic -- UART_TXD
	);
end entity;

architecture RTL of Briscola_Datapath is
	signal punti_cpu							: integer := 0;
	signal punti_player 						: integer := 0;
	signal mano									: mano_cpu;
	signal briscola_partita						: carta;
	signal carta_giocata_pl						: carta;
	signal carta_giocata_cpu 					: carta;
	signal AZZERA_CARTE_GIOCATE					: std_logic;
	signal AZZERA_TOKEN							: std_logic;
	signal FINE_TURNO							: std_logic;
	signal sig_carta_da_lanciare_cpu			: carta;
	signal sig_carta_giocata_pl					: carta;
	signal sig_token_int						: std_logic_vector(0 to 7) := (others => '0');
	signal sig_token_presa						: std_logic_vector(0 to 7) := (others => '0');
	signal sig_punti_cpu						: std_logic_vector(0 to 7) := (others => '0');
	signal sig_punti_player						: std_logic_vector(0 to 7) := (others => '0');
	
	signal data_transmitted 		: std_logic_vector(0 to 7);
	signal data_transmitted_carta 	: std_logic_vector(0 to 7);
	signal data_transmitted_token 	: std_logic_vector(0 to 7);
	signal data_transmitted_punti 	: std_logic_vector(0 to 20);
	signal data_valid_RX 			: std_logic; 
	signal data_received			: std_logic_vector(0 to 7);
	signal TX_ENABLE_CARTA			: std_logic; 
	signal TX_ENABLE_TOKEN			: std_logic;
	signal R_ENABLE					: std_logic;
	signal starts_cpu				: boolean;
	signal indice_carta_giocata		: integer := -1;
	
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
	LEDGREEN(7) <= INVIA_RISULTATO_FINALE;
	LEDGREEN(4) <= PENULTIMO_TURNO;
	LEDGREEN(3) <= DECIDI_CARTA;
	LEDGREEN(2) <= INVIA_RISULTATO;
	LEDGREEN(1) <= NUOVO_TURNO;
	LEDGREEN(0) <= FINE_TURNO;
		
	rx : UART_RX port map(CLOCK, RX_LINE, data_valid_RX, data_received);
	
	RiceviMano: process(CLOCK, RESET, NUOVO_TURNO)
		variable mano_counter	: integer 	:= 0;
		variable carta_ricevuta	: carta;
		variable briscola 		: boolean;
		variable seme_carta 	: seme; 
		variable numero 		: integer;
		variable valore			: integer;
		variable token_counter	: integer 	:= 0;
		variable carta_reset 	: carta 	:= (0, DENARI, 0, false);
		variable carta_in_arrivo: std_logic := '0';
		variable carta_counter	: integer 	:= 0;
		variable stop_ric_mano	: std_logic := '0';		-- indica la fine della ricezione della mano
	begin
		if(RESET = '1') then
			for i in 0 to 2 loop 
				mano(i) <= carta_reset;
			end loop;
		
		elsif(rising_edge(CLOCK)) then	
			if(NUOVO_TURNO = '1') then 
				token_counter := 0;
				carta_counter := 0;
				--sig_carta_giocata_pl <= carta_reset;
			end if;

			data_transmitted_token <= sig_token_int OR sig_token_presa;
			
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
					if(numero = 12) then 
						numero := 1;
					elsif(numero = 13) then
						carta_ricevuta := carta_reset;
						numero := 0;
					end if;
					valore := getValorefromNumber(numero);
				
					carta_ricevuta := (numero, seme_carta, valore, briscola);
					
					if((carta_counter > 1) OR (mano_counter > 3 AND stop_ric_mano = '1') ) then
						sig_carta_giocata_pl <= carta_ricevuta;			-- carta giocata dal player
						stop_ric_mano := '0';
						carta_counter := 0;
					elsif(carta_in_arrivo = '1') then
						mano(indice_carta_giocata) <= carta_ricevuta;	-- carta da mettere nella mano
					else
						if(stop_ric_mano = '0') then
							if(mano_counter = 3) then 
								briscola_partita <= carta_ricevuta;		-- briscola della partita
							elsif(mano_counter < 3) then
								mano(mano_counter) <= carta_ricevuta;	-- carta nella mano iniziale
							end if;
						end if;
					end if;
					
					if(stop_ric_mano = '0' AND mano_counter > 3) then 
						if(data_received(7) = '1') then
							carta_counter := carta_counter + 1;
						end if;
					end if;
		
					mano_counter := mano_counter + 1;

					R_ENABLE <= '0';
					if(mano_counter = 4) then
						MANO_RICEVUTA <= '1';
						stop_ric_mano := '1';
					else 
						MANO_RICEVUTA <= '0';
					end if;
	
				elsif(data_received(7) = '0') then -- è un token
					token_counter := token_counter + 1;
					case data_received (0 to 3) is
						when "0101" =>			-- reset token
							data_transmitted_token <= ((data_transmitted_token AND "00001111") OR "10100000");
							AZZERA_TOKEN <= '1';
							sig_carta_giocata_pl <= carta_reset;
							token_counter := 0;
							carta_in_arrivo := '1';
							carta_counter := 0;
						when others =>
							AZZERA_TOKEN <= '0';
					end case;
					
					if(token_counter = 1) then
						if(data_received(7) = '0') then
							case data_received(4 to 6) is
								when "111" =>
									TOKEN_CPU <= '1';
									starts_cpu <= true;
								when "000" =>
									TOKEN_CPU <= '0';
									starts_cpu <= false;
								when others => 
							end case;
						end if;
					else
						if(data_received(7) = '0') then
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
			end if;
		end if;
	end process;
	
	--
	DecidiCarta : process(CLOCK, RESET, DECIDI_CARTA, PENULTIMO_TURNO, FINE_TURNO, sig_carta_giocata_pl, NUOVO_TURNO) is 
		variable carta_reset 		: carta := (0, DENARI, 0, false);
		variable carta_da_lanciare 	: carta;
		variable num_carichi 		: integer := 0;
		variable num_briscole 		: integer := 0;
		variable indice 			: integer := 0;
		
	begin
		if(rising_edge(CLOCK)) then
		
			if(NUOVO_TURNO = '1') then
				carta_da_lanciare := carta_reset;
				sig_carta_da_lanciare_cpu <= carta_reset;
			end if;
			
			if(INVIA_RISULTATO_FINALE = '1') then
				TX_ENABLE_CARTA <= '0';
			end if;
			
			if(DECIDI_CARTA = '1') then
				if(PENULTIMO_TURNO = '0') then
					if(sig_carta_giocata_pl.numero = 0) then 
						if(isLiscio(mano)) then 
							indice := getCartaLiscia(mano);
						else 
							num_briscole := getNumeroBriscole(mano);
							num_carichi := getNumeroCarichi(mano);
							indice := determinaSituazioneNoLisci(num_carichi, num_briscole, mano);
						end if; --IS LISCIO
					else
						indice := decidiCartaFase2(mano, sig_carta_giocata_pl);
					end if; -- FASE 1 o FASE 2
				else -- PENULTIMO_TURNO = 1 
					indice := decidiPenultimo(mano, briscola_partita);	
				end if; -- GIOCATA NORMALE
				indice_carta_giocata <= indice;
				carta_da_lanciare := mano(indice);
				sig_carta_da_lanciare_cpu <= carta_da_lanciare;
				data_transmitted_carta <= fromCartaToByte(carta_da_lanciare);
				TX_ENABLE_CARTA <= TASTO_PREMUTO;
	
				if((carta_da_lanciare.numero > 0) AND (sig_carta_giocata_pl.numero > 0)) then
					sig_token_int <= "00000000";
					VALUTA_PRESA <= '1';
				else
					sig_token_int <= reverse_vector("01110101");
					VALUTA_PRESA <= '0';
				end if;
			end if; -- DECIDI CARTA
			
			if(FINE_TURNO = '1') then
				VALUTA_PRESA <= '0';
			elsif(sig_carta_giocata_pl.numero > 0) then
				VALUTA_PRESA <= '1';
			else 
				VALUTA_PRESA <= '0';
			end if;
		end if;
	end process;
	
	
	-- 
	ValutaInviaRisultato : process(CLOCK, INVIA_RISULTATO, AZZERA_TOKEN, sig_carta_da_lanciare_cpu, sig_carta_giocata_pl) is
		variable risultato 		: boolean;
		variable byte_result	: std_logic_vector (0 to 7);
		variable pt_CPU			: integer := 0;
		variable pt_PL			: integer := 0;
		variable read_once		: std_logic := '0';
		
	begin 
		if(rising_edge(CLOCK)) then
			
	LCD3 <= numberTo7SegmentDisplay(pt_CPU);
	LCD1 <= numberTo7SegmentDisplay(pt_PL);
			if(AZZERA_TOKEN = '1') then
				sig_token_presa <= "00000000";
				FINE_TURNO <= '0';
				read_once := '0';
			end if;
			if(INVIA_RISULTATO = '1') then
				if((sig_carta_da_lanciare_cpu.numero > 0) AND (sig_carta_giocata_pl.numero > 0)) then
					if(starts_cpu) then 
						risultato := valutaPresa(sig_carta_da_lanciare_cpu, sig_carta_giocata_pl);
						if(risultato) then
							if(read_once = '0') then
								pt_CPU := pt_CPU + sig_carta_da_lanciare_cpu.valore + sig_carta_giocata_pl.valore;
								read_once := '1';
							end if;
							byte_result := "00001111"; -- non tocca al giocatore, ha preso la CPU
						else
							if(read_once = '0') then
								pt_PL := pt_PL + sig_carta_da_lanciare_cpu.valore + sig_carta_giocata_pl.valore;
								read_once := '1';
							end if;
							byte_result := "01110000"; -- tocca al giocatore, ha preso il giocatore
						end if;
					else 
						risultato := valutaPresa(sig_carta_giocata_pl, sig_carta_da_lanciare_cpu);
						if(risultato) then 
							if(read_once = '0') then
								pt_PL := pt_PL + sig_carta_da_lanciare_cpu.valore + sig_carta_giocata_pl.valore;
								read_once := '1';
							end if;
							byte_result := "01110000"; -- tocca al giocatore, ha preso il giocatore
						else
							if(read_once = '0') then
								pt_CPU := pt_CPU + sig_carta_da_lanciare_cpu.valore + sig_carta_giocata_pl.valore;
								read_once := '1';
							end if;
							byte_result := "00001111"; -- non tocca al giocatore, ha preso la CPU
						end if;
					end if;
					
					punti_cpu <= pt_CPU;
					punti_player <= pt_PL;
					TX_ENABLE_TOKEN <= INVIA_RISULTATO;
					sig_token_presa <= reverse_vector(byte_result);
					FINE_TURNO <= '1';
				else
					byte_result := "00000000";
					FINE_TURNO <= '0';
				end if;
			elsif(INVIA_RISULTATO_FINALE = '1') then
				TX_ENABLE_TOKEN <= '0';
				sig_punti_cpu(0 to 6) <= reverse_vector(std_logic_vector(to_unsigned(punti_cpu, 7)));
				sig_punti_cpu(7) <= '1';
				sig_punti_player(0 to 6) <= reverse_vector(std_logic_vector(to_unsigned(punti_player, 7)));
				sig_punti_player(7) <= '1';
				data_transmitted_punti(1 to 8) <= sig_punti_player;
				data_transmitted_punti(11 to 18) <= sig_punti_cpu;
			end if;
		end if;
	
	end process;

	
	
--	LEDGREEN(7) <= TX_ENABLE_CARTA;			
--	LEDGREEN(6) <= TX_ENABLE_TOKEN;
	
	InviaByte : process(CLOCK, TX_ENABLE_CARTA, TX_ENABLE_TOKEN, INVIA_RISULTATO_FINALE) is
		-- Variabili per la trasmissione
		variable count 				: integer range 0 to 5207 	:= 5207; 	--9600 baud generator variable (50MHz/9600)
		variable bit_number 		: integer range 0 to 10 	:= 0;  		--start bit+8 data bits+stop bit
		variable count_tk 			: integer range 0 to 5207 	:= 5207; 	--9600 baud generator variable (50MHz/9600) for token
		variable bit_number_tk		: integer range 0 to 10 	:= 0;  		--start bit+8 data bits+stop bit for token
		variable count_START 		: integer range 0 to 5207 	:= 5207; 	--9600 baud generator variable (50MHz/9600)
		variable bit_number_START	: integer range 0 to 10 	:= 0;  		--start bit+8 data bits+stop bit
		variable count_FINAL		: integer range 0 to 5207 	:= 5207; 	--9600 baud generator variable (50MHz/9600)
		variable bit_number_FINAL	: integer range 0 to 30 	:= 0;  		--start bit+8 data bits+stop bit (x2 byte)
		variable byte_not_sent 		: boolean 					:= true;
		variable byte_not_sent_START: boolean 					:= true;
		variable byte_not_sent_tk 	: boolean 					:= true;
		variable byte_not_sent_FIN 	: boolean 					:= true;
		variable card_sent			: boolean					:= false;
		variable token_punti		: std_logic_vector(0 to 7)	:= "00001010";
	begin
		if(rising_edge(CLOCK)) then
		
			if(TASTO_INIZIO = '1') then
				if (count_START = 5207 AND byte_not_sent_START) then
					if (bit_number = 0) then
						TX_LINE <= '0'; --start bit
					elsif(bit_number = 9) then	
						TX_LINE <= '1'; -- stop bit
					elsif((bit_number > 0) and (bit_number < 9))  then
						TX_LINE <= data_transmitted_carta(bit_number-1); --8 data bits
					end if;
					bit_number := bit_number + 1;
					if(bit_number = 10) then --resetting the bit number
						byte_not_sent_START := false;
						bit_number := 0;
					end if;
				end if;
					
				count_START := count_START + 1;
				if (count_START = 5208) then --resetting the baud generator counter
					count_START := 0;
				end if;
			else 
				byte_not_sent_START := true;
			end if;

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
			
			if(INVIA_RISULTATO_FINALE = '1' AND TASTO_PREMUTO = '1') then
				if (count_FINAL = 5207 AND byte_not_sent_FIN) then
					if (bit_number_FINAL = 0 OR bit_number_FINAL = 10 OR bit_number_FINAL = 20) then
						TX_LINE <= '0'; --start bit
					elsif(bit_number_FINAL = 9 OR bit_number_FINAL = 19 OR bit_number_FINAL = 29) then	
						TX_LINE <= '1'; -- stop bit
					elsif(bit_number_FINAL > 0 AND bit_number_FINAL < 10) then
						TX_LINE <= token_punti(bit_number_FINAL-1);
					elsif(((bit_number_FINAL > 10) and (bit_number_FINAL < 19)) OR ((bit_number_FINAL > 20) AND (bit_number_FINAL < 29)))  then
						TX_LINE <= data_transmitted_punti(bit_number_FINAL-11); --8 data bits
					end if;
					bit_number_FINAL := bit_number_FINAL + 1;
					if(bit_number_FINAL = 30) then --resetting the bit number
						byte_not_sent_FIN := false;
						bit_number_FINAL := 0;
					end if;
				end if;
					
				count_FINAL := count_FINAL + 1;
				if (count_FINAL = 5208) then --resetting the baud generator counter
					count_FINAL := 0;
				end if;
			else 
				byte_not_sent_FIN := true;
			end if;
		end if;
			
	end process;
	
end architecture;