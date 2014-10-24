package CONSTANTS is
	constant WORD_SIZE :		integer := 32;

	-- WRF
	constant wrfNumBit :				integer	:= 32;	-- numBit;
	constant wrfNumGlobals :			integer := 8;	-- numGlobals;
	constant wrfNumWindows :			integer := 7;	-- numWindows;
	constant wrfNumRegsPerWin :			integer := 8;	-- numRegsPerWin;
	constant wrfNumRegs :				integer := 128; -- 16 + 2*7*8; -- numGlobals + 2*numWindows*numRegsPerWin;
	constant wrfLogNumRegs:				integer := 5;	-- LOG(numRegsPerWin*3+numGlobals)
	constant wrfLogNumRegsPerWin :		integer := 3;	-- LOG(numRegsPerWin)
end CONSTANTS;
