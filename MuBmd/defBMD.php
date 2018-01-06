<?php

$defs = array(
	'text' => [],
	'skill' => [],
	'item' => [],
	'filter' => [],
);

$defFiles = scanDir('_defBMD');
forEach($defFiles as $file) {
	if($file != '.' && $file != '..')
		require('_defBMD/'.$file);
}

?>