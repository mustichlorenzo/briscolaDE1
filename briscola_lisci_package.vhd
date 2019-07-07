library ieee;
library briscola_package;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use briscola_package.briscola_package.all;

-------------------------------------------
-- Funzioni utilizzate in presenza di lisci
-------------------------------------------
package briscola_lisci_package is

	-- determina se nella mano sono presenti dei lisci 
	function isLiscio(mano : mano_cpu) return boolean;
	
	-- restituisce vero se è presente un carico nella mano, falso altrimenti
	function isCarico(mano : mano_cpu) return boolean;
	
	-- restituisce vero se esistono un liscio e un carico con lo stesso seme, falso altrimenti
	function isCartaStessoSemeCarico(mano : mano_cpu) return boolean;
	
	-- restituisce l'indice della carta liscia più bassa
	function getCartaLisciaPiuBassa(mano : mano_cpu) return integer;
	
	-- restituisce l'indice della carta liscia dello stesso seme nel carico
	function getCartaStessoSemeCarico(mano : mano_cpu) return integer;
	
	-- FUNZIONE di TOP-LEVEL --
	-- restituisce l'indice della carta liscia più adeguata
	function getCartaLiscia(mano : mano_cpu) return integer;
	
end package;

-- ====================================================================================================================

package body briscola_lisci_package is 

	-- restituisce vero se nella mano della CPU sono presente dei lisci, falso altrimenti
	function isLiscio(mano: mano_cpu) return boolean is
	begin 
		for i in 0 to 2 loop
			if (mano(i).valore = 0 AND mano(i).briscola = false) then
				return true;
			end if;
		end loop;
		
		return false;
	end function;


	-- restituisce vero se è presente un carico nella mano, falso altrimenti
	function isCarico(mano : mano_cpu) return boolean is
	begin 
		for i in 0 to 2 loop
			if(NOT mano(i).briscola) then
				if(mano(i).valore = 10 OR mano(i).valore = 11) then 
					return true;
				end if;
			end if;
		end loop;
	
		return false;
	end function;
	

	-- restituisce vero se esistono un liscio e un carico con lo stesso seme, falso altrimenti
	function isCartaStessoSemeCarico(mano : mano_cpu) return boolean is
		variable seme_carico : seme;
	begin 
		for i in 0 to 2 loop
			if(NOT mano(i).briscola) then
				if(mano(i).valore = 11 OR mano(i).valore = 10) then 
					seme_carico := mano(i).seme_carta;
					exit;
				end if;
			end if;
		end loop;
		
		for i in 0 to 2 loop 
			if(NOT mano(i).briscola) then
				if(mano(i).valore = 0 AND mano(i).seme_carta = seme_carico) then 
					return true;
				end if;
			end if;
		end loop;
		
		return false;
	end function;
	

	-- restituisce l'indice della carta lisca dello stesso seme nel carico
	function getCartaStessoSemeCarico(mano : mano_cpu) return integer is
		variable seme_carico : seme;
		variable indice		: integer;
	begin 
		for i in 0 to 2 loop
			if(NOT mano(i).briscola) then
				if(mano(i).valore = 11 OR mano(i).valore = 10) then 
					seme_carico := mano(i).seme_carta;
					exit;
				end if;
			end if;
		end loop;
		
		for i in 0 to 2 loop 
			if(NOT mano(i).briscola) then
				if(mano(i).valore = 0 AND mano(i).seme_carta = seme_carico) then 
					indice := i;
				end if;
			end if;
		end loop;
		
		return indice;
	end function;	
	

	-- restituisce l'indice della carta lisca più bassa
	function getCartaLisciaPiuBassa(mano : mano_cpu) return integer is
		variable indice 				: integer;
		variable carta_piu_bassa 	: integer;
	begin
		for i in 0 to 2 loop
			if(NOT mano(i).briscola) then 
				if(mano(i).valore = 0) then 
					carta_piu_bassa := mano(i).numero;
					indice := i;
				end if;			
			end if;
		end loop;
		
		for i in 0 to 2 loop 
			if(NOT mano(i).briscola) then 
				if(mano(i).valore = 0) then 
					if(mano(i).numero < carta_piu_bassa) then 
						carta_piu_bassa := mano(i).numero;
						indice := i;
					end if;
				end if;
			end if;
		end loop;
		
		return indice;
	end function;
	
	
	-- FUNZIONE di TOP_LEVEL --
	-- restituisce l'indice della carta liscia più adeguata
	function getCartaLiscia(mano : mano_cpu) return integer is
		variable indice : integer;
	begin 
		if(isCarico(mano)) then 
			if(isCartaStessoSemeCarico(mano)) then 
				indice := getCartaStessoSemeCarico(mano);
			else 
				indice := getCartaLisciaPiuBassa(mano);
			end if;
		else 
			indice := getCartaLisciaPiuBassa(mano);
		end if;
	
		return indice;
	end function;

end package body;