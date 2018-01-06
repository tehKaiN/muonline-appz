<?php

// config
$updateSrvPath = 'd:/mu/z p퀉t/mupatch.nefficient.co.kr/';
$verDest = '01.00.25';
$verStart = '00.52';
// config end

?><!doctype html>
<html>
	<head>
		<meta http-equiv="content-type" content="text/html;charset=euc-kr">
		<title>Mu client assembler</title>
	</head>
	<body>
<?php

function parseVerNum($str) {
	$out = explode('.',$str);
	$out[0] = @$out[0]+0;
	$out[1] = @$out[1]+0;
	$out[2] = @$out[2]+0;
	return $out;
}

function outVerNum($arr) {
	$out = substr('0'.$arr[0], -2).'.'.substr('0'.$arr[1], -2);
	if($arr[2] || $arr[0])
		$out .= '.'.substr('0'.$arr[2], -2);
	return $out;
}

function incVerNum($ver) {
	global $updateSrvPath;
	$ver = parseVerNum($ver);
	while($ver[2] != 99) {
		$ver[2] += 1;
		if(file_exists($updateSrvPath.outVerNum($ver)))
			return outVerNum($ver);
	}
	$ver[2] = 0;
	while($ver[1] != 99) {
	$ver[1] += 1;
	if(file_exists($updateSrvPath.outVerNum($ver)))
		return outVerNum($ver);
	}
	$ver[1] = 0;
	$ver[0] += 1;
	return outVerNum($ver);
}

$outPath = 'out_'.$verStart.'_to_'.$verDest.'/';
@mkdir($outPath);


$verCurr = $verStart;

while(str_replace('.', '', $verCurr)+0 <= str_replace('.', '', $verDest)+0) {
	echo '=== VER '.$verCurr.' ===<br><br>';
	
	$currCopyPath = $outPath;
	$dir = '';
	$filesPath = $updateSrvPath.$verCurr.'/';
	$compressed = 0;
	$newToolVersion = 0;
	
	$list = file($filesPath.'list.inf');
	forEach($list as $listLine) {
		set_time_limit(2);
		if($listLine[0] == '#') {
			// META string
			$meta = trim($listLine, "#\r\n");
			switch($meta) {
				case 'TEST_SERVER':
					echo '<span style="color: red;">test server update!</span><br>';
					break;
				case 'COMPRESSED':
					echo '<span style="color: blue">Compressed with bzip2!</span><br>';
					$compressed = 1;
					break;
				case 'NEWTOOLVERSION':
					echo '<span style="color: orange;">New update tool version!</span><br>';
					$newToolVersion = 1;
					break;
				default:
					echo 'unexpected flag: ',$meta,'<br>';
					die();
			}
		} elseif($listLine[0] == '0') {
			// dir string
			$dir = explode(' ', $listLine);
			$dir = str_replace('\\', '/', trim($dir[1], "\"\'\n\r"));
			$currCopyPath = $outPath.$dir.'/';
			if($newToolVersion) {
				$filesPath = $updateSrvPath.$verCurr.'/'.$dir.'/';
			}
			@mkDir($currCopyPath, 0777, true);
		} elseif($listLine[0] == '"') {
			// file string
			$fileName = trim($listLine, "\"\'\n\r");
			if($compressed) {
				$hBz = bzOpen($filesPath.$fileName, 'r');
				$content = '';
				while(!feof($hBz)) {
					$content .= bzread($hBz);
				}
				bzClose($hBz);
				file_put_contents($currCopyPath.substr($fileName, 0, -4), $content);
				echo '<div style="font-size:12px;">extracted <span style="color: #555;">',ltrim($dir.'/','/'),'</span>',substr($fileName, 0, -4),'</div>';
			} else {
				copy($filesPath.$fileName, $currCopyPath.$fileName);
				echo '<div style="font-size:12px;">copied <span style="color: #555;">',ltrim($dir.'/','/'),'</span>',$fileName,'</div>';
			}
		}
	}
	
$verCurr = incVerNum($verCurr);
echo '<br>';
}


?>
	</body>
</html>