<?php
require_once("../config.php");
require_once("functions.php");

if ($CFG->debug) {
	ini_set('display_errors', 1);
	ini_set('display_startup_errors', 1);
	error_reporting(E_ALL);
}


if (isset($_GET['action'])) {
	#echo $_GET['action'];
	switch ($_GET['action']) {
		case 'educapes_download_stop':
			system("echo 'educapes_download_stop' > ../../service/pipe", $retVal);
			echo $retVal;
			break;

		case 'educapes_download_start':
			system("echo 'educapes_download_start' > ../../service/pipe", $retVal);
			echo $retVal;
			break;

		case 'test':
			system("echo 'test' > ../../service/pipe", $retVal);
			echo $retVal;
			break;

		case 'export_all':
			system("echo 'export_all' > ../../service/pipe", $retVal);
			echo $retVal;
			break;

		case 'start':
			system("echo 'start' > ../../service/pipe", $retVal);
			echo $retVal;
			break;

		case 'stop':
			system("echo 'stop' > ../../service/pipe", $retVal);
			echo $retVal;
			break;

		case 'access_mode_ip':
			system("echo 'access_mode ip' > ../../service/pipe", $retVal);
			echo $retVal;
			break;

		case 'update_network':
      $ip = filter_input(INPUT_GET, 'ip', FILTER_SANITIZE_SPECIAL_CHARS);
      $ip = ($ip == "") ? "null" : $ip;
      $dhcp = filter_input(INPUT_GET, 'dhcp', FILTER_SANITIZE_SPECIAL_CHARS);
      if ($ip != "null") {
				if (exec("echo " . $ip . " | grep -Eo '^(([0-9]{1,3})\.){3}[0-9]{1,3}$'") == "") {
					echo "badIp";
					die();
				}
			}
			$cmd = "echo 'update_network " . $dhcp . " " . $ip . "' > ../../service/pipe";
			system($cmd, $retVal);
			echo $retVal;
			break;

		case 'access_mode_name':
			system("echo 'access_mode name' > ../../service/pipe", $retVal);
			echo $retVal;
			break;

		case 'setup_dns':
			if (!empty($_POST['email']) && (!empty($_POST['pass'])) && (!empty($_POST['domain'])) ) {
				system("echo 'setup_dns " . $_POST['email'] . " " . $_POST['pass'] . " " . $_POST['domain'] . "' > ../../service/pipe;", $retVal);
				echo $retVal;
			} else {
				echo 666;
			}
			break;

		case 'get_progress':
			if (isset($_GET['subject'])) {
				switch ($_GET['subject']) {
					case 'educapes_download':
						echo return_progress_educapes();
						break;
					case 'service':
						echo return_service_log();
						break;

					default:
						echo "Nenhum objeto válido especificado.";
						break;
				}
			} else {
				echo "Nenhum objeto especificado.";
			}
			#echo return_progress_educapes();
			break;

		default:
			echo "Ação inválida especificada.";
			break;
	}
	#sleep(1000);
} else {
	echo "Nenhum dado foi fornecido";
}
