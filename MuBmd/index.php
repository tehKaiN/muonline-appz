<?php

define('EOL', "\n");

// ------ BMD BLOCK DEFS ------ //

require('defBMD.php');

// ------ RESEARCH BMD ------ //

function deXOR($fName) {
	$xor = [0xFC, 0xCF, 0xAB];
	$content = file_get_contents($fName.'.bmd');
	$d = strLen($content);
	for($i = 0; $i != $d; ++$i) {
		$content[$i] = chr(ord($content[$i]) ^ $xor[$i%sizeOf($xor)]);
	}
	file_put_contents($fName.'_dexor.bmd', $content);
}

// ------ NEW BMD FNS ------ //

function readTXT($fName, &$def) {
	// TODO: ...
}

function readBMD($fName, &$def) {
	$out = [];
	$hIn = fOpen($fName.'.bmd', 'rb');
	// Header
	if($def['header']) {
		$out['header'] = fRead($hIn, $def['header']);
	}
	else {
		$out['header'] = '';
	}
	// Block count
	$size = filesize($fName.'.bmd');
	$size -= $def['header']+$def['footer'];
	if($size%$def['blockSize']) {
		echo 'invalid block/header/footer size! size: ',$size,', blockSize: ',$def['blockSize'],'<br>';
		return null;
	}
	$blockCount = $size/$def['blockSize'];
	// Read blocks
	$xor = [0xFC, 0xCF, 0xAB];
	$out['blocks'] = [];
	for($j = 0; $j != $blockCount; ++$j) {
		$block = fRead($hIn, $def['blockSize']);
		// deXOR
		for($i = 0; $i != $def['blockSize']; ++$i) {
			$block[$i] = chr(ord($block[$i]) ^ $xor[$i%sizeOf($xor)]);
		}
		// Slice to fields
		$fieldOffset = 0;
		$blockOut = [];
		forEach($def['fields'] as $field) {
			$fieldVal = subStr($block, $fieldOffset, $field[2]);
			$fieldOffset += $field[2];
			if($field[1] == 'int' ) {
				if($field[2] == 1) {
					$fieldVal = ord($fieldVal);
				}
				elseif($field[2] == 2) {
					$fieldVal = (ord($fieldVal[1])<<8)+ord($fieldVal[0]);
				}
			}
			else if($field[1] == 'txt') {
				$fieldVal = substr($fieldVal, 0, strPos($fieldVal, "\0"));
			}
			$blockOut[] = $fieldVal;
		}
		if($def['groupSize']) {
			@$out['blocks'][floor($j/$def['groupSize'])][$j%$def['groupSize']] = $blockOut;
		} else {
			$out['blocks'][] = $blockOut;
		}
	}
	// Footer
	if($def['footer']) {
		$bmdContent['footer'] = fRead($hIn, $def['footer']);
	}
	fClose($hIn);
	return $out;
}

function writeTXTgroup($h, &$def, $items) {
	// Prepare group header and fmt
	$header = '// Idx';
	$fmt = '%6u';	
	forEach($def['fields'] as $fieldIdx => $field) {
		$colWidth = strLen($field[0]);
		// var_dump($colWidth);
		forEach($items as $item) {
			$colWidth = max($colWidth, strLen($item[$fieldIdx].''));
		}
		$fmt .= ' %'.$colWidth;
		if($field[1] == 'txt')
			$fmt .= 's';
		elseif($field[1] == 'int')
			$fmt .= 'd';
		$header .= sprintf(' %'.$colWidth.'s', $field[0]);
	}
	$header .= EOL;
	$fmt .= EOL;
	// Write group
	fWrite($h, $header);
	forEach($items as $itemIdx => $item) {
		$ln = vsprintf($fmt, array_merge([$itemIdx], $item));
		fWrite($h, $ln);
	}
	fWrite($h, 'end'.EOL.EOL);
}

function writeTXT($fName, &$def, $in) {
	$hOut = fOpen($fName.'.txt', 'wb');
	fWrite($hOut, '// ------------------'.EOL.'// BMD exported by'.EOL.'// KaiN client toolz'.EOL.'// ------------------'.EOL.EOL);
	// Footer
	if($def['header']) {
	// ...
	}
	// Write blocks
	if($def['groupSize']) {
		forEach($in['blocks'] as $groupIdx => $group) {
			fWrite($hOut, $groupIdx.EOL);
			writeTXTgroup($hOut, $def, $group);
		}
	}
	else {
		writeTXTgroup($hOut, $def, $in['blocks']);
	}
	// Footer
	if($def['footer']) {
	// ...
	}
	fClose($hOut);
}

function writeBMDgroup($h, &$def, $items) {
	$xor = [0xFC, 0xCF, 0xAB];
	forEach($items as $item) {
		$block = '';
		// merge fields
		forEach($def['fields'] as $fieldIdx => $field) {
			if($field[1] == 'txt')
				$block .= str_pad($item[$fieldIdx], $field[2], "\0");
			elseif($field[1] == 'int') {
				if($field[2] == 1)
					$block .= chr($item[$fieldIdx]);
				elseif($field[2] == 2)
					$block .= chr($item[$fieldIdx] & 0xFF) . chr($item[$fieldIdx] >> 8);
			}
		}
		$d = strLen($block);
		if($d != $def['blockSize']) {
			echo 'Wrong block size!';
			return 0;
		}
		// XOR
		for($i = 0; $i != $d; ++$i)
			$block[$i] = chr(ord($block[$i]) ^ $xor[$i % sizeOf($xor)]);
		// write
		fWrite($h, $block);
	}
}

function writeBMD($fName, &$def, $in) {
	$hOut = fOpen($fName.'.bmd', 'wb');
	// Header
	if($def['header']) {
		// ...
	}
	// Write groups
	if($def['groupSize']) {
		forEach($in['blocks'] as $group)
			writeBMDgroup($hOut, $def, $group);
	}
	else
		writeBMDgroup($hOut, $def, $in['blocks']);
	// Footer
	if($def['footer']) {
		// ...
	}
	fClose($hOut);
}

function translateBMD(&$destDef, &$src, &$dest) {
	forEach($destDef['fields'] as $fieldIdx => $field)
		if($field[0] == $destDef['translateField']) {
			$tIdx = $fieldIdx;
			break;
		}
	if($destDef['groupSize']) {
		forEach($dest['blocks'] as $groupIdx => $group)
			forEach($group as $itemIdx => $item) {
			$destName = &$dest['blocks'][$groupIdx][$itemIdx][$tIdx];
			$srcName = &$src['blocks'][$groupIdx][$itemIdx][$tIdx];
				if(strLen($srcName) && strLen($destName))
					$destName = $srcName;
			}
	}
	else {
		forEach($dest['blocks'] as $itemIdx => $item) {
			$destName = &$dest['blocks'][$itemIdx][$tIdx];
			$srcName = &$src['blocks'][$itemIdx][$tIdx];
			if(strLen($srcName) && strLen($destName))
				$destName = $srcName;
		}
	}
}

// ------ NPCNAME ------

function readNpcNameTXT($fName) {
	$names = [];
	$lines = file($fName.'.txt');
	forEach($lines as &$line) {
		$line = trim($line);
		$line = str_replace("\t", ' ', $line);
		$line = str_replace('  ', '', $line);
		$qStart = strPos($line, '"');
		if($qStart !== false) {
			$no = subStr($line, 0, strPos($line, ' '));
			$name = subStr($line, $qStart+1, strPos($line, '"', $qStart+1)-($qStart+1));
			$names[$no] = $name;
		}
	}
	ksort($names);
	return $names;
}

function translateNpcName(&$srcNames, &$destNames) {
	forEach($destNames as $idx => &$name) {
		if(@strLen($srcNames[$idx]) && @strLen($name)) {
			$name = $srcNames[$idx];
		}
	}
}

function writeNpcNameTXT($fName, $names) {
	$hOut = fOpen($fName.'.txt', 'wb');
	$nameLength = 0;
	forEach($names as &$name) {
		$name = '"'.$name.'"';
		$nameLength = max($nameLength, strLen($name));
	}
	$head = sprintf('// Idx Show %'.$nameLength.'s'."\n", 'Name');
	$fmt =  '   %3u    1 %'.$nameLength.'s'."\n";
	fWrite($hOut, $head);
	forEach($names as $idx => &$name) {
		fPrintf($hOut, $fmt, $idx, $name);
	}
	fClose($hOut);
}

// ------ META ------ //

function convertDir_BMD2TXT($dir) {
	convertText_BMD2TXT($dir.'/text');
}

function fixDir($dir) {
	global $defs;
	@mkDir($dir.'_fixed');
	
	// translate Text.BMD
	if(file_exists($dir.'/Text.bmd')) {
		echo 'Text.bmd<br>';
		$translateSrc = readBMD('mobius/Text', $defs['text']['all']); // TODO: txt
		$translateDest = readBMD($dir.'/Text', $defs['text']['all']);
		translateBMD($defs['text']['all'], $translateSrc, $translateDest);
		writeBMD($dir.'_fixed/Text', $defs['text']['all'], $translateDest);
		writeTXT($dir.'_fixed/Text', $defs['text']['all'], $translateDest);
	}
	
	// clear Filter.BMD
	if(file_exists($dir.'/Filter.bmd')) {
		echo 'Filter.bmd<br>';
	// 	clearFilter($dir.'/filter', $dir.'_fixed/Filter');
	}
	
	// translate Item.BMD
	if(file_exists($dir.'/Item.bmd')) {
		echo 'Item.bmd<br>';
		$translateSrc = readBMD('mobius/Item', $defs['item']['100']); // TODO: txt
		$translateDest = readBMD($dir.'/Item', $defs['item']['074']);
		translateBMD($defs['item']['074'], $translateSrc, $translateDest);
		writeBMD($dir.'_fixed/Item', $defs['item']['074'], $translateDest);
		writeTXT($dir.'_fixed/Item', $defs['item']['074'], $translateDest);
	}
	
	// translate Skill.BMD
	if(file_exists($dir.'/Skill.bmd')) {
		echo 'Skill.bmd<br>';
		$translateSrc = readBMD('mobius/skill', $defs['skill']['100']); // TODO: txt
		$translateDest = readBMD($dir.'/skill', $defs['skill']['074']);
		translateBMD($defs['skill']['074'], $translateSrc, $translateDest);
		writeBMD($dir.'_fixed/Skill', $defs['skill']['074'], $translateDest);
		writeTXT($dir.'_fixed/Skill', $defs['skill']['074'], $translateDest);
	}
	
	// translate NpcName(kor).txt
	if(file_exists($dir.'/NpcName(kor).txt')) {
		echo 'NpcName(kor).txt<br>';
		$translateSrc = readNpcNameTXT('mobius/NpcName(eng)');
		$translateDest = readNpcNameTXT($dir.'/NpcName(kor)');
		translateNpcName($translateSrc, $translateDest);
		writeNpcNameTXT($dir.'_fixed/NpcName(kor)', $translateDest);
	}
}

fixDir('0.74');

// deXOR('0.74/skill');
// deXOR('mobius/skill');

// $item = readBMD('0.74_fixed/item', $defs['item']['074']);
// writeBMD('0.74_fixed/item2', $defs['item']['074'], $item);
// writeTXT('0.74_fixed/item', $defs['item']['074'], $item);

// $item = readBMD('mobius/item', $defs['item']['100']);
// writeTXT('mobius/item', $defs['item']['100'], $item);

?>