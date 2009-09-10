<?

// simple mysql database wrapper

class DataBase
{
	var $connid;
	var $erg;

	function DataBase ($host,$user,$passwort)
	{
		if(!$this->connid = mysql_connect($host, $user, $passwort))
		{
			echo "error connecting ...";
			echo "host: $host<br>user: $user<br>password: $passwort";
			// maybe you should not print the line above :P
			die();
		}
		return $this->connid;
	}
	
	function Close ()
	{
		mysql_close($this->connid);
	}
	
	function Select ($db)
	{
		if (!mysql_select_db($db, $this->connid))
		{
			echo "error selecting DB...";
			die();
		}
	}

	function Query ($sql)
	{
		if (!$this->erg = mysql_query($sql, $this->connid))
		{
			echo "error sending query ...";
			echo mysql_error();
			echo "<br>";
			echo $sql;
			die();
		}
		return $this->erg;
	}
	
	function NumOfRows ()
	{
		return mysql_num_rows($this->erg);
	}
	
	function ReadNext ()
	{
		$result = mysql_fetch_assoc($this->erg);
		return $result;
	}
}

?>