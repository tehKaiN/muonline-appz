<?php

	function fReadUWord(&$h) {
		$ret = 0;
		$ret = ord(fRead($h, 1)) + (ord(fRead($h, 1)) << 8);
	
		return $ret;
	}
	
	$fName = 'message_kor.wtf';
	// $fName = 'message.wtf';

	$hIn = fOpen($fName, 'rb');
	
	$wtfStrings = array();
	
	echo 'HeadCode: 0x',dechex(ord(fRead($hIn, 1))),'<br>';
	echo 'Version: 0x',dechex(ord(fRead($hIn, 1))), '<br>';
	
	$caption = fRead($hIn, 22);
	$caption = str_replace("\0", '<span style="color:#444; border: solid 1px #ccc; display: inline-block; margin: 0 1px;">0</span>', $caption);
	echo 'Caption: ',$caption,'<br>';
	
	$stringCount = fReadUWord($hIn);
	echo 'Expected string count: ',$stringCount,'<br>';
	
	$unk = fReadUWord($hIn);
	echo 'Unk1: ',dechex(ord($unk)),'<br>';
	
	while($stringCount--) {
		$num = fReadUWord($hIn);
		$len = fReadUWord($hIn);
		echo '<div style="font-size: 14px;"><span style="color: #555;">Decoded string no</span> ',$num,', <span style="color: #555;">length:</span>',$len,'</div>';
		if($len) {
			$bfr = fRead($hIn, $len);
			for($j = strLen($bfr); $j--;) {
				$bfr[$j] = chr(ord($bfr[$j]) ^ 0xCA);
			}
			$wtfStrings[$num] = $bfr;

		} else {
			$wtfStrings[$num] = '';
		}
	}
	
	$tail = fRead($hIn, 4096);
	$tail = str_replace("\0", '<span style="color:#444; border: solid 1px #ccc; display: inline-block; margin: 0 1px;">0</span>', $tail);
	echo 'Tail: ',$tail,'<br>';
	var_dump($tail);
		
	fClose($hIn);
	ksort($wtfStrings);
	// var_dump($wtfStrings);
	// var_dump($wtfStrings[110]);
	
	// for($i = 0; $i != strLen($wtfStrings[110]); ++$i) {
		// echo ord($wtfStrings[110][$i]),' ';
	// }

	$hOut = fOpen(substr($fName, 0, -3).'txt', 'w');
	forEach($wtfStrings as $idx => $txt) {
		fWrite($hOut, $idx."\t".$txt."\n");
	}
	fClose($hOut);
	
?>