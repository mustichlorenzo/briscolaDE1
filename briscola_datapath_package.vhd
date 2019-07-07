library ieee;
library briscola_package;
library briscola_lisci_package;
library briscola_situazioniNoLisci_package;
library briscola_utility_package;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use briscola_package.briscola_package.all;
use briscola_lisci_package.briscola_lisci_package.all;
use briscola_situazioniNoLisci_package.briscola_situazioniNoLisci_package.all;
use briscola_utility_package.briscola_utility_package.all;

package briscola_datapath_package is
	------------------------------------------------------------------------
	-- Firma delle funzioni per il calcolo dei punti della presa
	------------------------------------------------------------------------
	function decidiCarta(mano : mano_cpu) return integer;
 
   -- valuta i punti vinti da uno dei due giocatori in un determinito turno
	-- true = vince la prima carta, false = vince la seconda carta
	function valutaPresa(carta1 : carta; carta2 : carta) return boolean; 			

end package;

-- ====================================================================================================================

package body briscola_datapath_package is 

	--
	function decidiCarta(mano : mano_cpu) return integer is 
		variable indice, num_briscole, num_carichi : integer;
	begin
		if(isLiscio(mano)) then 
			indice := getCartaLiscia(mano);
		else
			num_briscole := getNumeroBriscole(mano);
			num_carichi := getNumeroCarichi(mano);
			indice := determinaSituazioneNoLisci(num_carichi, num_briscole, mano);
		end if;	
		
	end function;

	------------------------------------------------------------------------
	-- Funzioni per il calcolo dei punti della presa
	------------------------------------------------------------------------
	
	-- valuta quanti punti il giocatore o la CPU fanno nel momento in cui finisce il turno
	-- true = vince la prima carta, false = vince la seconda carta
	function valutaPresa(carta1: carta; carta2: carta) return boolean is
	begin
		if (carta1.seme_carta = carta2.seme_carta) then -- carte dello stesso seme
			if (carta1.valore = carta2.valore) then	-- carte lisce dello stesso seme, prende la più grande
				return (carta1.numero > carta2.numero);
			else
				return (carta1.valore > carta2.valore);
			end if;
		else
			if (carta1.briscola = false AND carta2.briscola = false) then 
				return true;	-- carta1 è vincente
			else
				return carta1.briscola;		-- in questo ramo, le carte hanno semi diversi e una delle 2 è briscola (se è vero carta1 briscola
													-- altrimenti carta2 è brsicola)
			end if;
		end if;
		
	end function;	

end package body;