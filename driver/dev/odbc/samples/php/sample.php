<?php

putenv("LD_LIBRARY_PATH=/usr/local/lib");  //This may be blocked by php security

echo $LD_LIBRARY_PATH;

//putenv("ODBCINSTINI=/path/to/odbcinst.ini"); //this location will be determined by your driver install.

//putenv("ODBCINI=/path/to/odbc.ini"); //odbc.ini contains your DSNs, location determined by your driver install.

$dsn="SAMPLES"; 

$user="_SYSTEM"; 

$password="sys"; 

 

$sql="SELECT * FROM sample.person";   

if ($conn_id=odbc_connect("$dsn","","")){

echo "connected to DSN: $dsn";

if($result=odbc_do($conn_id, $sql)) {

echo "executing '$sql'";

echo "Results: ";

odbc_result_all($result);

echo "freeing result";

odbc_free_result($result);

}else{

echo "can not execute '$sql' ";

}

echo "closing connection $conn_id";

odbc_close($conn_id);

}else{

echo "can not connect to DSN: $dsn ";

}

?>

