<?php
	
	//this file gets called by the IC background process on the user's mac
	//it returns the queued messages
	//really no rocket science :)
	
	function PollMessage ()
	{
		include ('config/config.php');
		require_once ('libs/database.php');
	
		$db = new DataBase($db_server, $db_user, $db_password);
		$db->Select($db_name);
		$db->Query ("SELECT * FROM messages ORDER BY id DESC LIMIT 2");
			
		$data = $db->ReadNext();
		
		//no message in queue - return nop
		if ($data == null)
		{
			echo "none";
			return;
		}		
		
		
/*		echo "<pre>";
		print_r($data);
		echo "</pre>";*/
		
		$id = $data['id'];
		$message = $data['message'];
		
		//return the command to client
		echo $message;

		//delete message from queue
		$db = new DataBase($db_server, $db_user, $db_password);
		$db->Select($db_name);
		$db->Query ("DELETE FROM messages WHERE id = '$id';");
		
		
	}
	
	PollMessage();
	
?>