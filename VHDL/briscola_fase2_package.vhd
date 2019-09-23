library ieee;
library briscola_package;
library briscola_situazioniNoLisci_package;
library briscola_lisci_package;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use briscola_package.briscola_package.all;
use briscola_situazioniNoLisci_package.briscola_situazioniNoLisci_package.all;
use briscola_lisci_package.briscola_lisci_package.all;

package briscola_fase2_package is
	function decidiCartaFase2(mano : mano_cpu; cartaTerra : carta) return integer;
	function getCartaNoBriscolaPresa(mano : mano_cpu; cartaTerra : carta) return integer;
end package;

package body briscola_fase2_package is
	
	function decidiCartaFase2(mano : mano_cpu; cartaTerra : carta) return integer is
		variable num_carichi		: integer;
		variable num_briscole	: integer;
		variable indice			: integer;
	begin
		indice := getCartaNoBriscolaPresa(mano, cartaTerra);
		
		if(indice < 0) then
			if(isLiscio(mano)) then 
				indice := getCartaLiscia(mano);
			else
				num_briscole := getNumeroBriscole(mano);
				num_carichi := getNumeroCarichi(mano);
				indice := determinaSituazioneNoLisci(num_carichi, num_briscole, mano);
			end if;	
		end if;
		
		return indice;
	end function;
	
	function getCartaNoBriscolaPresa(mano: mano_cpu; cartaTerra: carta) return integer is
		variable indice: integer;
		variable cartaCorrente: carta;
	begin
		cartaCorrente := mano(0);
		indice := -1;
		
		for i in 0 to 2 loop
			if(mano(i).numero > 0) then
				if(NOT mano(i).briscola) then
					if(mano(i).seme_carta = cartaTerra.seme_carta) then 
						if(mano(i).valore > cartaTerra.valore AND mano(i).valore >= cartaCorrente.valore) then 
							indice := i;
							cartaCorrente := mano(i);
						end if;
					end if;
				end if;
			end if;
		end loop;
		
		return indice;
	end function;


end package body;
