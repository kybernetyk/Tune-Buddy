<?php

function generateSerial ($name)
{

//	$name = "Jaroslaw Szpilewski";
	$original_name = $name;
	
	echo "name: $name\n";
	echo "md5: " . md5($name)."\n";
	
	$name = utf8_decode ($name);
	
	echo "len: ".strlen($name);
	echo "\n";
	
	$len = strlen ($name);
	
	if ($len < 10)
		$len = 15;
	
	if ($len > 99)
		$len = 50;
	
	$one = $len - 3;
	$two = $len;
	$three = $len + 3;
	$four = $len - 5;
	
	$string = $one.$two.$three.$four.$two.$four.$one.$three.$three.$four.$one.$two.$one.$three.$four.$one;
	
	$string = strtoupper ($string);
	$string = md5($string);
	
	$name = $string;
	$name = md5($original_name);
	
	$step1 = trim ($name);
	echo "step1: $step1\n";

	$step2 = str_replace (" ", "", $step1);
	echo "step2: $step2\n";

	$step3 = $step2;
	
	if (strlen ($step3) < 20 )
		$step3 = str_pad ($step3, 20, "K");
	else if (strlen ($step3) > 20 )
		$step3 = substr ($step3, 0, 20);
	
	echo "step3: $step3\n";

	$step4 = "";

	for ($i = 0; $i < 5; $i++)
	{
		$step4 .= substr ($step3, $i*4,4);
		if ($i < 4)
			$step4 .= "-"; 
	}

	echo "step4: $step4\n";

	$step5 = str_rot13 ($step4);
	$step5 = strtoupper ($step5);
	
	echo "serial: $step5";
	echo "\n";
	
	return $step5;
}

$bla = generateSerial("Jaroslaw Szpilewski");

?>
