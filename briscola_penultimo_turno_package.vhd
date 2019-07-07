library ieee;
library briscola_package;
library briscola_situazioniNoLisci_package;
library briscola_lisci_package;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use briscola_package.briscola_package.all;
use briscola_situazioniNoLisci_package.briscola_situazioniNoLisci_package.all;
use briscola_lisci_package.briscola_lisci_package.all;

package briscola_penultimo_turno_package is
	function getBriscolaPiuBassa(mano : mano_cpu) return integer;
	function getCartaValorePiuAlto(mano : mano_cpu) return integer;
	function getPrimaCartaLiscia(mano : mano_cpu) return integer;

	-- FUNZIONI DI TOP LEVEL
	function decidiPenultimo(mano : mano_cpu; briscola_partita : carta) return integer;
	function decidiPenultimoFase2(mano : mano_cpu; briscola_partita : carta; carta_a_terra : carta) return integer;
end package;

package body briscola_penultimo_turno_package is

	function getBriscolaPiuBassa(mano : mano_cpu) return integer is
		variable indice 		: integer;
		variable carta_temp 	: carta;
	begin 
		carta_temp := mano(0);
		indice := 0;
		
		for i in 1 to 2 loop 
			if(carta_temp.valore < mano(i).valore) then 
				carta_temp := mano(i);
				indice := i;
			end if;
		end loop;
		
		return indice;
	end function;
	
	
	function getPrimaCartaLiscia(mano : mano_cpu) return integer is
		variable indice : integer := 0;
	begin 
		for i in 0 to 2 loop 
			if(mano(i).valore = 0 AND (NOT mano(i).briscola)) then 
				indice := i;
				exit;
			end if;
		end loop;
		
		return indice;
	end function;

	
	function getCartaValorePiuAlto(mano : mano_cpu) return integer is
		variable indice 		: integer := 0;
		variable carta_temp 	: carta;
	begin			
		carta_temp := mano(0);
	
		for i in 1 to 2 loop 
			if(mano(i).valore > 0 AND (NOT mano(i).briscola)) then 
				if(mano(i).valore > carta_temp.valore) then 
					carta_temp := mano(i);
					indice := i;
				end if;
			end if;
		end loop;
		
		if(indice = 0) then 
			if(carta_temp.valore = 0 OR carta_temp.briscola) then 
				indice := -1;
			end if;
		end if;
		
		return indice;
	end function;
	
	-- FUNZIONI DI TOP LEVEL
	function decidiPenultimo(mano : mano_cpu; briscola_partita : carta) return integer is
		variable indice 			: integer;
		variable num_briscole 	: integer;
		variable num_carichi 	: integer;
	begin 
		if(briscola_partita.valore > 0) then
			indice := getCartaValorePiuAlto(mano);
			if(indice = -1) then 
				num_briscole := getNumeroBriscole(mano);
				if(num_briscole = 3) then 
					indice := getBriscolaPiuBassa(mano);
				else 
					indice := getPrimaCartaLiscia(mano);
				end if;
			end if;
		else
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

	
	function decidiPenultimoFase2(mano : mano_cpu; briscola_partita : carta; carta_a_terra : carta) return integer is
		variable indice 			: integer;
		variable num_briscole 	: integer;
		variable num_carichi 	: integer;
	begin 
		if(briscola_partita.valore > 0) then
			indice := getCartaValorePiuAlto(mano);
			if(indice = -1) then 
				num_briscole := getNumeroBriscole(mano);
				if(num_briscole = 3) then 
					indice := getBriscolaPiuBassa(mano);
				else 
					indice := getPrimaCartaLiscia(mano);
				end if;
			end if;
		else
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

end package body;