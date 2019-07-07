library ieee;
library briscola_package;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use briscola_package.briscola_package.all;

----------------------------------------------------------
-- Funzioni per la determinazione delle diverse situazioni
----------------------------------------------------------
package briscola_situazioniNoLisci_package is
		
	-------------------------------------------------
	-- Firma delle funzioni per le diverse situazioni
	-------------------------------------------------
	
	-- SITUAZIONE 1 --
	
	-- restituisce l'indice della carta più bassa tra quelle in mano
	function getCartaPiuBassa(mano : mano_cpu) return integer;
	
	-- restituisce l'indice della carta più bassa dello stesso seme di un carico
	-- altrimenti restituisce la più bassa in assoluto
	function situazione1(mano : mano_cpu) return integer;
	

	-- SITUAZIONE 2 --
	
	-- restituisce l'indice della carta che non è un carico (no liscio) 
	function situazione2(mano : mano_cpu) return integer;
	

	-- SITUAZIONE 3 --

	-- restituisce vero se nella mano ci sono più carichi dello stesso seme, falso altrimenti
	function isCarichiStessoSeme(mano : mano_cpu) return boolean;
	
	-- restituisce l'indice del carico dello stesso seme più basso 
	function getCaricoStessoSemePiuBasso(mano : mano_cpu) return integer;

	-- restituisce vero se nella mano sono presenti degli assi, falso altrimenti
	function getIndiceAssi(mano : mano_cpu) return integer; 
	
	-- in caso di più carichi dello stesse seme, restituisce quello più basso 
	-- altrimenti, se ho assi restituisco l'indice del primo, altrimenti l'indice di una carta casuale
	function situazione3(mano : mano_cpu) return integer; 
	
	
	-- SITUAZIONE 4 --
	
	-- restituisce l'indice della briscola
	function getBriscola(mano : mano_cpu) return integer;
	
	-- restituisce vero se la briscola presente è con punti (sia figure che carichi), falso altrimenti
	function isBriscolaConPunti(mano : mano_cpu) return boolean;
	
	-- restituisce l'indice della carta non briscola e con pochi punti (una figura)
	function getCartaNonBriscolaNonCarico(mano : mano_cpu) return integer;
	
	-- numero carichi: 1, numero briscole: 1
	function situazione4(mano : mano_cpu) return integer;
	
	
	-- SITUAZIONE 5 --
	 
	-- restituisce l'indice della briscola più bassa
	function situazione5(mano : mano_cpu) return integer; 

	
	-- SITUAZIONE 6 --
	
	-- restituisce l'indice del carico più alto
	function getCaricoPiuAlto(mano : mano_cpu) return integer;
		
	-- numero carichi: 2, numero briscole: 1
	function situazione6(mano : mano_cpu) return integer;
	
	
	-- SITUAZIONE 7 --

	-- in presenza di tre briscole, restituisce l'indice della più bassa
	function situazione7(mano : mano_cpu) return integer;

   ----------------------------------------------------------------------
	-- Firma delle funzioni per la determinazione delle diverse situazioni
	----------------------------------------------------------------------

	-- FUNZIONE di TOP_LEVEL --
	-- restituisce il numero di carichi in mano 
	function getNumeroCarichi(mano : mano_cpu) return integer;
	
	-- FUNZIONE di TOP_LEVEL --
	-- restituisce il numero di briscole in mano
	function getNumeroBriscole(mano : mano_cpu) return integer;
	
	-- FUNZIONE di TOP_LEVEL --
	-- determina le varie situazioni in cui la CPU si può ritrovare in assenza di lisci nella propria mano
	function determinaSituazioneNoLisci(num_carichi : integer; num_briscole : integer; mano : mano_cpu) 
		return integer;

end package;

-- ====================================================================================================================

package body briscola_situazioniNoLisci_package is 

   -------------------------------------
	-- Funzioni per le diverse situazioni
	-------------------------------------
	
	-- SITUAZIONE 1 --
	
	-- resistuisce l'indice della carta con valore più basso 
	function getCartaPiuBassa(mano : mano_cpu) return integer is
		variable indice 				:	integer;
		variable carta_piu_bassa	: 	carta;
	begin
		carta_piu_bassa := mano(0);
		indice := 0;
		
		for i in 1 to 2 loop
			if(mano(i).valore < carta_piu_bassa.valore) then
				carta_piu_bassa := mano(i);
				indice := i;
			end if;
		end loop;
		
		return indice;
	end function;
	
	-- numero carichi: 1, numero briscole: 0
	function situazione1(mano : mano_cpu) return integer is 
		variable seme_carico 	: seme;
		variable indice 			: integer;
	begin
		-- individua il seme del carico 
		for i in 0 to 2 loop
			if(mano(i).numero = 1 OR mano(i).numero = 3) then
				seme_carico := mano(i).seme_carta;
				exit;
			end if;
		end loop;
		
		-- se esistono carte non carico dello stesse seme del carico restituisce la prima trovata
		-- la carta più bassa, altrimenti
		for i in 0 to 2 loop
			if(mano(i).seme_carta = seme_carico) then
				if(mano(i).briscola = false) then
					if(mano(i).valore /= 0 AND mano(i).valore /= 10 AND mano(i).valore /=11) then 
						indice := i;
					else 
						indice := getCartaPiuBassa(mano);
					end if;
				end if;
			end if;
		end loop;
		
		return indice;
	end function;
		
		
	-- SITUAZIONE 2--
	
	-- numero carichi: 2, numero briscole: 0
	function situazione2(mano : mano_cpu) return integer is 
		variable indice 				: integer;
		variable carta_piu_bassa 	: carta;
	begin
		carta_piu_bassa := mano(0);
		indice := 0;

		for i in 0 to 2 loop
			if (mano(i).valore /= 11 OR mano(i).valore /= 10) then
				if (NOT mano(i).briscola) then
					if(mano(i).valore < carta_piu_bassa.valore) then
						indice := i; 
					end if;
				end if;
			end if;
		end loop;
			
		return indice;
	end function;

	
	-- SITUAZIONE 3 --
	
	-- restituisce vero se nella mano ci sono più carichi dello stesso seme, falso altrimenti
	function isCarichiStessoSeme(mano : mano_cpu) return boolean is 
		variable seme_primo_carico : seme;
	begin 
		seme_primo_carico := mano(0).seme_carta;
		
		for i in 1 to 2 loop 
			if(mano(i).valore = 11 OR mano(i).valore = 10) then 
				if(mano(i).seme_carta = seme_primo_carico) then
					return true;
				end if;
			end if;
		end loop;
		
		return false;
	end function;
	
	-- restituisce l'indice del carico dello stesso seme più basso 
	function getCaricoStessoSemePiuBasso(mano : mano_cpu) return integer is 
		variable indice 				: integer;
		variable primo_carico 		: carta;
		variable altro_carico		: carta;
	begin 
		for i in 0 to 2 loop 
			if(mano(i).valore = 11 OR mano(i).valore = 10) then 
				primo_carico := mano(i);
				indice := i;
				exit;
			end if;
		end loop;
		
		altro_carico := primo_carico;
		for i in 0 to 2 loop 
			if(mano(i).valore = 11 OR mano(i).valore = 10) then 
				if(mano(i).seme_carta = primo_carico.seme_carta) then
					if(mano(i).valore < primo_carico.valore) then 
						altro_carico := mano(i);
						indice := i;
					end if;
				end if;
			end if;
		end loop;
		
		return indice;
	end function;
	
	-- restituisce l'indice dell'asso, l'indice della prima carta altrimenti
	function getIndiceAssi(mano : mano_cpu) return integer is 
		variable indice 	: integer;
	begin
		for i in 0 to 2 loop
			if(mano(i).numero = 1) then
				indice := i;
				exit;
			else
				indice := 0;
				exit;
			end if;
		end loop;
		
		return indice;
	end function;
		
	-- numero carichi: 3, numero briscole: 0
	function situazione3(mano : mano_cpu) return integer is
		variable indice : integer;
	begin 
		if(isCarichiStessoSeme(mano)) then 
			indice := getCaricoStessoSemePiuBasso(mano);
		else 
			indice := getIndiceAssi(mano);	
		end if;
		
		return indice;
	end function;
	
	
	-- SITUAZIONE 4 --
	
	-- restituisce l'indice della briscola
	function getBriscola(mano : mano_cpu) return integer is
		variable indice : integer;
	begin
		for i in 0 to 2 loop
			if(mano(i).briscola) then
				indice:= i;
			end if; 
		end loop;

		return indice;	
	end function;
	
	-- restituisce vero se la briscola presente è con punti (sia figure che carichi), falso altrimenti
	function isBriscolaConPunti(mano : mano_cpu) return boolean is
	begin
		for i in 0 to 2 loop
			if(mano(i).briscola) then
				if (mano(i).valore = 10 OR mano(i).valore = 11)then 
					return true;
				end if;
		 	end if;
		end loop;
		
		return false;
	end function;
	
	-- restituisce l'indice della carta non briscola e con pochi punti (una figura)
	function getCartaNonBriscolaNonCarico(mano: mano_cpu) return integer is
		variable indice : integer;
	begin	
		for i in 0 to 2 loop
			if(NOT mano(i).briscola) then
				if(mano(i).numero /= 1 AND mano(i).numero /= 3)then 
					indice := i;
				end if;
		 	end if;
		end loop;

		return indice;
	end function;
	
	-- numero carichi: 1, numero briscole: 1
	function situazione4(mano : mano_cpu) return integer is
		variable indice         : integer;
		variable seme_carico 	: seme;
	begin
		-- individua il seme del carico 
		for i in 0 to 2 loop
			if(mano(i).numero = 1 OR mano(i).numero = 3) then
				seme_carico := mano(i).seme_carta;
				exit;
			end if;
		end loop;
		
		-- se esistono carte non carico dello stesse seme del carico restituisce la prima trovata
		-- la carta più bassa, altrimenti
		for i in 0 to 2 loop
			if(mano(i).seme_carta = seme_carico) then
				if(mano(i).briscola = false) then
					if(mano(i).valore /= 10 AND mano(i).valore /= 11) then 
						indice := i;
						exit;
					else 
						if(isBriscolaConPunti(mano)) then
					 		indice:= getCartaNonBriscolaNonCarico(mano);
							exit;
					 	else 
							indice := getBriscola(mano);
							exit;
					end if;
				end if;	 
				end if;
			end if;
		end loop;

	 	return indice;
	end function;

	
	-- SITUAZIONE 5 --
	
	-- numero carichi: 1, numero briscole: 2
	function situazione5(mano : mano_cpu) return integer is 
		variable indice 			: integer;
		variable carta_piu_bassa 	: carta;
	begin 
		carta_piu_bassa := mano(0);
		indice := 0;
		
		for i in 1 to 2 loop
			if(mano(i).briscola) then
				if (mano(i).valore < carta_piu_bassa.valore) then 
					carta_piu_bassa := mano(i);
					indice := i;
				end if;	
			end if;
		end loop;	
				
		return indice;
	end function;
	
	
	-- SITUAZIONE 6 --
	
	-- restituisce l'indice del carico più alto
	function getCaricoPiuAlto(mano : mano_cpu) return integer is
		variable indice 				: integer;
		variable carico_piu_alto	: integer;
	begin 
		-- inizializza le variabili
		for i in 0 to 2 loop
			if(NOT mano(i).briscola) then 
				carico_piu_alto := mano(i).valore;
				indice := i;
			end if;
		end loop;
		
		for i in 0 to 2 loop
			if(NOT mano(i).briscola) then
				if(mano(i).valore > carico_piu_alto) then
					carico_piu_alto := mano(i).valore;
					indice := i;			
				end if;
			end if;
		end loop;

		return indice;
	end function;
		
	-- numero carichi: 2, numero briscole: 1
	function situazione6(mano : mano_cpu) return integer is
		variable indice     		: integer;
		variable seme_carico		: integer;
	begin 			
		if(isCarichiStessoSeme(mano)) then
			if(isBriscolaConPunti(mano)) then
				indice := getCaricoStessoSemePiuBasso(mano);
			else 
				indice := getBriscola(mano);			
			end if;
		else
			indice := getCaricoPiuAlto(mano);
		end if;

		return indice;
	end function;
	
	
	-- SITUAZIONE 7 --
	
	-- numero carichi: 0, numero briscole: 3
	-- in presenza di tre briscole, restituisce l'indice della più bassa
	function situazione7 (mano : mano_cpu) return integer is
	begin
		return getCartaPiuBassa(mano);
		
	end function;

	
	----------------------------------------------------------
	-- Funzioni per la determinazione delle diverse situazioni
	----------------------------------------------------------
	
	-- FUNZIONE di TOP_LEVEL --
	-- restituisce il numero di briscole presenti nella mano della CPU
	function getNumeroBriscole(mano: mano_cpu) return integer is
		variable num_briscole : integer := 0;
	begin 
		for i in 0 to 2 loop
			if (mano(i).briscola) then
				num_briscole := num_briscole + 1;
			end if;
		end loop;
		
		return num_briscole;
	end function;

	-- FUNZIONE di TOP_LEVEL --
	-- restituisce il numero di carichi presenti nella mano della CPU
	function getNumeroCarichi(mano : mano_cpu) return integer is
		variable numero_carichi : integer := 0;
	begin
		for i in 0 to 2 loop		--le carte della mano devono essere o 3 o asso o il valore della briscola deve essere uguale a false
			if (NOT mano(i).briscola) then
				if (mano(i).numero = 3 OR mano(i).numero = 1) 
					then numero_carichi := numero_carichi + 1;
				end if;
			end if;
		end loop;
		
		return numero_carichi;
	end function;

	-- FUNZIONE di TOP_LEVEL --
	-- determina le varie situazioni in cui la CPU si può ritrovare in assenza di lisci nella propria mano
	function determinaSituazioneNoLisci(num_carichi : integer; num_briscole : integer; mano : mano_cpu) return integer is
	begin 
		if (num_carichi = 1 AND num_briscole = 0) then 
			return situazione1(mano);
		elsif (num_carichi = 2 AND num_briscole = 0) then	
			return situazione2(mano);
		elsif (num_carichi = 3 AND num_briscole = 0) then	
			return situazione3(mano);
		elsif (num_carichi = 1 AND num_briscole = 1) then	
			return situazione4(mano);
		elsif (num_carichi = 1 AND num_briscole = 2) then	
			return situazione5(mano);
		elsif (num_carichi = 2 AND num_briscole = 1) then	
			return situazione6(mano);
		elsif (num_carichi = 0 AND num_briscole = 3) then	
			return situazione7(mano);
		end if;
		
		return 0;
	end function;
		
end package body;  