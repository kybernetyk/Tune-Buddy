<?php
	function EnqueueMessage ($message)
	{
			include ('config/config.php');
			require_once ('libs/database.php');
			
			$db = new DataBase($db_server, $db_user, $db_password);
			$db->Select($db_name);
			
			$query = "INSERT INTO messages (
					message
					)
					VALUES (
					'$message'
					);";
					
			$db->Query ($query);
	}

	function PrintMainMenu ()
	{
		echo "<h1>Tune Control 0.1</h1>";
		echo "<font size=+6>";
		echo "<a href='index.php?message=play'>Play |&gt;</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
		echo "<a href='index.php?message=stop'>Stop ||</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
		echo "<a href='index.php?message=prev'>Prev &lt;</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
		echo "<a href='index.php?message=next'>Next &gt;</a>";
		echo "<p>";
		echo "<a href='index.php?message=vol_inc'>Volume +</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
		echo "<a href='index.php?message=vol_dec'>Volume -</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
		echo "<a href='index.php?message=mute_unmute'>Mute/Unmute</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
		
		echo "</font>";
	}

	function main ()
	{
	
		if (isset($_GET['message']))
		{
			$msg = $_GET['message'];
			EnqueueMessage($msg);
		}
		
		PrintMainMenu();
	}
	
	main();
?>