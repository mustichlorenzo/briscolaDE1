library ieee;
library briscola_package;
library briscola_utility_package;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use briscola_package.briscola_package.all;
use briscola_utility_package.briscola_utility_package.all;

entity Briscola_Controller is
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
end entity;


architecture RTL of Briscola_Controller is
		type s_briscola is (S_IDLE, S_MANO_RICEVUTA, S_DECIDI_LANCIA_CARTA,
								S_ASPETTO_TOKEN, S_INVIA_RISULTATO);
		signal s_current : s_briscola := S_IDLE; 
begin
		
	LEDRED(3) <= MANO_RICEVUTA;
	LEDRED(2) <= TOKEN_CPU;
	LEDRED(1) <= PRESA_CPU;
	LEDRED(0) <= VALUTA_PRESA;
	
	process(CLOCK) is
		variable numTurni : integer;
		variable tasto_premuto : boolean := false;
	begin 
		if(rising_edge(CLOCK)) then
			case s_current is
				-- STATO 0
				when S_IDLE =>
					LCD_STATO <= numberTo7SegmentDisplay(0);
					
					DECIDI_CARTA <= '0';
					INVIA_RISULTATO <= '0';
					NUOVO_TURNO <= '0';
					PENULTIMO_TURNO <= '0';
					
					if(MANO_RICEVUTA = '1') then
						s_current <= S_MANO_RICEVUTA;
						DECIDI_CARTA <= '0';
						INVIA_RISULTATO <= '0';
						NUOVO_TURNO <= '1';
						numTurni := numTurni + 1;
					else 
						s_current <= S_IDLE;
					end if;
					
				-- STATO 1			
				when S_MANO_RICEVUTA =>
					LCD_STATO <= numberTo7SegmentDisplay(1);
					
					if(TOKEN_CPU = '1') then
						DECIDI_CARTA <= '1';
						INVIA_RISULTATO <= '0';
						NUOVO_TURNO <= '0';
						
						s_current <= S_DECIDI_LANCIA_CARTA;
						
						if(numTurni = 19) then
							PENULTIMO_TURNO <= '1';
						end if;
					
					else 
						s_current <= S_MANO_RICEVUTA;
					end if;
				
				-- STATO 2
				when S_DECIDI_LANCIA_CARTA =>
					LCD_STATO <= numberTo7SegmentDisplay(2);
					if(TASTO_PIGIATO = '0') then
						s_current <= S_DECIDI_LANCIA_CARTA;
					else
						tasto_premuto := true;
						if(tasto_premuto) then
							if(TOKEN_CPU = '1' AND VALUTA_PRESA = '1') then
								s_current <= S_INVIA_RISULTATO;
								DECIDI_CARTA <= '0';
								INVIA_RISULTATO <= '1';
								NUOVO_TURNO <= '0';
							elsif(TOKEN_CPU = '0') then
								s_current <= S_ASPETTO_TOKEN;
								DECIDI_CARTA <= '0';
								INVIA_RISULTATO <= '0';
								NUOVO_TURNO <= '0';
							else 
								s_current <= S_DECIDI_LANCIA_CARTA;
							end if;
						end if;
					end if;
				
				-- STATO 3
				when S_ASPETTO_TOKEN =>
					LCD_STATO <= numberTo7SegmentDisplay(3);
					
					if(TOKEN_CPU = '1' AND VALUTA_PRESA = '1') then
						s_current <= S_INVIA_RISULTATO;
						DECIDI_CARTA <= '0';
						INVIA_RISULTATO <= '1';
						NUOVO_TURNO <= '0';
					else
						s_current <= S_ASPETTO_TOKEN;
						DECIDI_CARTA <= '0';
						INVIA_RISULTATO <= '0';
						NUOVO_TURNO <= '0';
					end if;
					
				-- STATO 4
				when S_INVIA_RISULTATO =>
					LCD_STATO <= numberTo7SegmentDisplay(4);
					
					if(VALUTA_PRESA = '0') then
						s_current <= S_MANO_RICEVUTA;
						DECIDI_CARTA <= '0';
						INVIA_RISULTATO <= '0';
						NUOVO_TURNO <= '1';
					else
						s_current <= S_INVIA_RISULTATO;
					end if;	
					
			end case;
	
		end if;
	end process;

end architecture;