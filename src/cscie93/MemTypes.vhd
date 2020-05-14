-- synthesis library cscie93
library ieee;
use ieee.std_logic_1164.all;

package MemTypes is


type PS2States is 
	(
		WAITING,
		RCV0,
		RCV1,
		RCV2,
		RCV3,
		RCV4,
		RCV5,
		RCV6,
		RCV7,
		RCVP,
		RCVSTOP,
		RCVOK,
		RCVERR
	);
	
type ShiftKeyStates is
(
	NoShift,
	Shift,
	ShiftF0	
);


type BreakCodeStates is 
(
	Default,
	GotF0,
	PostF0
);

end;
