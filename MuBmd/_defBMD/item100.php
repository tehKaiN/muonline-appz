<?php

// ------ ITEM.BMD def ------
// version range: ~1.00

$defs['item']['100'] = [
	'blockSize' => 76,
	'groupSize' => 32,
	'header' => 0,
	'footer' => 4,
	'translateField' => 'Name',
	'fields' => [
		['Name', 'txt', 30],        // 30
		['Hands', 'int', 1],        // 31
		['Lvl', 'int', 1],          // 32
		['EqSlot', 'int', 1],       // 33
		['SkillID', 'int', 1],      // 34
		['X', 'int', 1],            // 35
		['Y', 'int', 1],            // 36
		['DmgMin', 'int', 1],       // 37
		['DmgMax', 'int', 1],       // 38
		['DefRate', 'int', 1],      // 39
		['Def', 'int', 1],          // 40
		['unk12', 'int', 1],        // 41
		['att/swSpeed', 'int', 1],  // 42
		['walkSpeed', 'int', 1],    // 43
		['Dur', 'int', 1],          // 44
		['unk16', 'int', 1],        // 45
		['unk17', 'int', 1],        // 46
		['reqSTR', 'int', 2],       // 48
		['reqAGI', 'int', 2],       // 50
		['reqENE', 'int', 2],       // 52
		['reqCMD', 'int', 2],       // 54
		['reqLVL', 'int', 1],       // 55
		['Value', 'int', 1],        // 56
		['unk28', 'int', 1],        // 57
		['unk29', 'int', 1],        // 58
		['unk30', 'int', 1],        // 59
		['unk31', 'int', 1],        // 60
		['ArmType', 'int', 1],      // 61
		['DW', 'int', 1],           // 62
		['DK', 'int', 1],           // 63
		['Elf', 'int', 1],          // 64
		['MG', 'int', 1],           // 65
		['DL', 'int', 1],           // 66
		['resIce', 'int', 1],       // 67
		['resPoison', 'int', 1],    // 68
		['resLightning', 'int', 1], // 69
		['resFire', 'int', 1],      // 70
		['resEarth', 'int', 1],     // 71
		['resWind', 'int', 1],      // 72
		['resWater', 'int', 1],     // 73
		['unk45', 'int', 1],        // 74
		['unk46', 'int', 1],        // 75
		['unk47', 'int', 1],        // 76
	],
];

?>