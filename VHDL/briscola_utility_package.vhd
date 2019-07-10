library ieee;
library briscola_package;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use briscola_package.briscola_package.all;

-----------------------------------
-- Funzioni ausiliarie	
-----------------------------------	
package briscola_utility_package is

	-- dato un numero, genera il suo codice equivalente per un display a 7 segmenti
	function numberTo7SegmentDisplay(numero : integer) return std_logic_vector; 	
	
	-- dato un carattere, genera il suo codice equivalente per un display a 7 segmenti
	function digitTo7SegmentDisplay(carattere : character) return std_logic_vector;
	
	-- dato il numero della carta, restituisce il suo valore
	function getValorefromNumber (numero: integer) return integer;
	
	-- inverte l'ordine dei bit in un qualsiasi vettore
	function reverse_vector (a: in std_logic_vector) return std_logic_vector;
	
	-- controlla se un vettore è pieno di zeri
	function vectorIsNotZero (vector: in std_logic_vector) return boolean;
	
	-- data la carta, la trasforma nel corrispondente byte
	function fromCartaToByte (cart: in carta) return std_logic_vector;

end package;

-- ====================================================================================================================

package body briscola_utility_package is 
	
	-- dato un numero della carta, genera il suo codice equivalenti per un display a 7 segmenti
	function numberTo7SegmentDisplay(numero: integer) return std_logic_vector is -- codifica little endian (6 to 0)
	begin
		if numero = 0 then
			return "0000001";     
		elsif numero = 1 then
			return "1001111";  
		elsif numero = 2 then
			return "0010010";  
		elsif numero = 3 then
			return "0000110";  
		elsif numero = 4 then
			return "1001100";  
		elsif numero = 5 then
			return "0100100";  
		elsif numero = 6 then
			return "0100000";  
		elsif numero = 7 then
			return "0001111";  
		elsif numero = 8 then
			return "0000000";   
		elsif numero = 9 then
			return "0000100"; 
		else 
			return "1111110"; -- "-"
		end if;
	end function;

	-- dato un carattere, genera il suo codice equivalente per un display a 7 segmenti
	function digitTo7SegmentDisplay(carattere : character) return std_logic_vector is
	begin 
		if (carattere = 'A' OR carattere = 'a') then 
			return "0001000";
		elsif (carattere = 'B' OR carattere = 'b') then
			return "1100000";
		elsif (carattere = 'C' OR carattere = 'c') then
			return "0110001";
		elsif (carattere = 'D' OR carattere = 'd') then
			return "1000010";
		elsif (carattere = 'E' OR carattere = 'e') then
			return "0110000";
		elsif (carattere = 'F' OR carattere = 'f') then
			return "0111000";
		elsif (carattere = 'G' OR carattere = 'g') then
			return "0100001";
		elsif (carattere = 'H' OR carattere = 'h') then
			return "1001000";
		elsif (carattere = 'I' OR carattere = 'i') then
			return "1111001";
		elsif (carattere = 'J' OR carattere = 'j') then
			return "1000011";
		elsif (carattere = 'L' OR carattere = 'l') then
			return "1110001";
		elsif (carattere = 'N' OR carattere = 'n') then
			return "1101010";
		elsif (carattere = 'O' OR carattere = 'o') then
			return "0000001";
		elsif (carattere = 'P' OR carattere = 'p') then
			return "0011000";
		elsif (carattere = 'Q' OR carattere = 'q') then
			return "0001100";
		elsif (carattere = 'R' OR carattere = 'r') then
			return "1111010";
		elsif (carattere = 'S' OR carattere = 's') then
			return "0100100";
		elsif (carattere = 'T' OR carattere = 't') then
			return "1110000";
		elsif (carattere = 'U' OR carattere = 'u') then
			return "1000001";
		elsif (carattere = 'Y' OR carattere = 'y') then
			return "1000100";
		else 
			return "1111110";
		end if;
	end function;
	
		-- dato il numero della carta, restituisce il suo valore
	function getValorefromNumber (numero: integer) return integer is
	begin
		if (numero = 1) then return 11;
		elsif (numero = 3) then return 10;
		elsif (numero = 8) then return 2;
		elsif (numero = 9) then return 3;
		elsif (numero = 10) then return 4;
		else return 0;
		end if;
	
	end function;
	
	-- inverte l'ordine dei bit in un qualsiasi vettore
	function reverse_vector (a: in std_logic_vector) return std_logic_vector is
	  variable result: std_logic_vector(a'RANGE);
	  alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
	begin
	  for i in aa'RANGE loop
		result(i) := aa(i);
	  end loop;
	  return result;
	end function;
	
	-- controlla se un vettore è pieno di zeri
	function vectorIsNotZero (vector: in std_logic_vector) return boolean is
	begin
		for i in 0 to vector'LENGTH-1 loop
			if (vector(i) = '1') then
				return true;
			end if;
		end loop;
		return false;
	end function;
	
	
	-- data la carta, la trasforma nel corrispondente byte
	function fromCartaToByte (cart: in carta) return std_logic_vector is
		variable byte_carta: std_logic_vector(0 to 7);
	begin
		if(cart.briscola) then
			byte_carta(0) := '1';
		else
			byte_carta(0) := '0';
		end if;
		case cart.seme_carta is
			when BASTONI =>
				byte_carta(1 to 2) := "00";
			when DENARI =>
				byte_carta(1 to 2) := "10";
			when COPPE =>
				byte_carta(1 to 2) := "01";
			when SPADE =>
				byte_carta(1 to 2) := "11";
		end case;
		byte_carta(3 to 6) := reverse_vector(std_logic_vector(to_unsigned(cart.numero, 4)));
		byte_carta(7) := '1';
		return byte_carta;
	end function;

end package body;
