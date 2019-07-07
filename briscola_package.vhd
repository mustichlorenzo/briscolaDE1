library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Definisce i tipi di dato, le costanti e le firme delle funzioni utili a Briscola
package briscola_package is

	-- Costanti 
	constant NUM_TURNI: integer := 20; -- numero di turni totali di una partita (40 carte, 2 giocatori, 20 turni)
	
	-- Tipi di dato 
	type vincitore is (GIOCATORE, CPU); -- definisce se il vincitore della partita sia o meno il giocatore piuttosto che l'FPGA
	type seme is (BASTONI, DENARI, COPPE, SPADE); -- definisce il seme della carta
	
	-- definisce il tipo carta con tutti i suoi attributi
	type carta is record
			numero		: integer;
			seme_carta	: seme;
			valore		: integer;
			briscola		: boolean;
	end record;
	
	type mazzo is array (0 to 39) of carta; -- definisce il numero di carte all'interno del mazzo
	type mano_cpu is array (0 to 2) of carta; -- definisce le tre carte che la CPU ha in mano in ogni momento

end package;