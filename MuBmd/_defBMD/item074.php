<?php

// ------ ITEM.BMD def ------
// version range: 0.74 - ???

$defs['item']['074'] = [
	'blockSize' => 55,
	'groupSize' => 16,
	'header' => 0,
	'footer' => 0,
	'translateField' => 'Name',
	'fields' => [
		['Name', 'txt', 30],        // 30
		['Hands', 'int', 1],        // 31
		['Lvl', 'int', 1],          // 32
		['X', 'int', 1],            // 33
		['Y', 'int', 1],            // 34
		['DmgMin', 'int', 1],       // 35
		['DmgMax', 'int', 1],       // 36
		['DefRate', 'int', 1],      // 37
		['Def', 'int', 1],          // 38
		['unk10', 'int', 1],        // 39
		['att/swSpeed', 'int', 1],  // 40
		['walkSpeed', 'int', 1],    // 41
		['Dur', 'int', 1],          // 42
		['reqSTR', 'int', 1],       // 43
		['reqAGI', 'int', 1],       // 44
		['reqENE', 'int', 1],       // 45
		['reqLVL', 'int', 1],       // 46
		['Value', 'int', 1],        // 47
		['DW', 'int', 1],           // 48
		['DK', 'int', 1],           // 49
		['Elf', 'int', 1],          // 50
		['MG', 'int', 1],           // 51
		['resIce', 'int', 1],       // 52
		['resPoison', 'int', 1],    // 53
		['resLightning', 'int', 1], // 54
		['resFire', 'int', 1],      // 55
	],
];

?>