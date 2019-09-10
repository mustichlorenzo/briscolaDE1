library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package briscola_audio_package is
	--AUDIO CONSTANTS
	constant LAST_FLASH_ADDR : positive := 1661635;
	constant AUDIO_PRESCALER_MAX : positive := 250;
	constant I2C_PRESCALER : positive := 60;

end package;