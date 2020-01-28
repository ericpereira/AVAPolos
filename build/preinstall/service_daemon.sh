#!/usr/bin/env bash

#Serviço AVAPolos
#Comandos suportados:
#download_stop $SERVICO -> Para o download de um serviço.
#download_start $SERVICO -> Resume ou força o download de um serviço
#check_services -> Checa os serviços para download.

source /etc/avapolos/header.sh
#source header.sh

PIPE="$SERVICE_PATH/pipe"
#PIPE="pipe"

export LOGGER_LVL="debug"
export LOGFILE_PATH="$LOG_PATH/service.log"

#Para desenvolvimento
#set +e

end() {
  echo "Serviço vai parar.." | log debug
  kill -s SIGTERM $educapes_pid
  rm -f $PIPE
  exit 0
}

update_moodle_hosts() {
  docker stop moodle > /dev/null
  docker start moodle > /dev/null
  ip=$(bash $INSTALL_SCRIPTS_PATH/get_ip.sh)
  echo "Atualizando hosts do Moodle com o ip: $ip." | log debug service
  docker exec moodle sh -c "echo \"$ip avapolos\" >> /etc/hosts"
}

trap end EXIT

educapes_download_stop() {
  if [ -z "$educapes_pid" ]; then
    echo "No educapes setup PID specified"
  fi
    touch /opt/educapes/no_check
    echo "Enviando SIGTERM para o processo $educapes_pid" | log debug
    kill -s SIGTERM $educapes_pid
}

educapes_download_start() {
    echo "Rodando check_educapes" | log debug
    rm -rf "$EDUCAPES_PATH/no_check"
    check_services
}

check_services() {
  cd $SERVICES_PATH
  for service in "$(cat enabled_services) $(cat disabled_services)"; do
    case $service in
      "educapes.yml")
        echo "Checando eduCAPES" | log debug
        run "$INSTALL_SCRIPTS_PATH/setup_educapes.sh" &
        educapes_pid=$!
      ;;
    esac
  done
}

readFromPipe() {
  IFS=' '
  args=()
    if read line <$PIPE; then
      read -a args <<< "$line"
      case $line in
        check_services )
        check_services
        ;;
        educapes_download_stop )
          if ! [ -z "${args[1]}" ]; then
            educapes_download_stop
            touch $SERVICE_PATH/done
          else
            echo "Comando inválido, argumentos insuficientes." | log error
          fi
        ;;
        educapes_download_start )
          if ! [ -z "${args[1]}" ]; then
            educapes_download_start
            touch $SERVICE_PATH/done
          else
            echo "Comando inválido, argumentos insuficientes." | log error
          fi
        ;;
        start )
          start
          touch $SERVICE_PATH/done
        ;;
        stop )
          touch $SERVICE_PATH/done
          sleep 4
          stop
        ;;
        access_mode* )
          if ! [ -z "${args[1]}" ]; then
            run "$SCRIPTS_PATH/access_mode.sh" "${args[1]}"
            touch $SERVICE_PATH/done
          else
            echo "Comando inválido, argumentos insuficientes." | log error
          fi
        ;;
        backup* )
          run "$SCRIPTS_PATH/backup.sh" "${args[@]}"
          touch $SERVICE_PATH/done
        ;;
        restore* )
          if ! [ -z "${args[1]}" ]; then
            run "$SCRIPTS_PATH/restore.sh" "${args[1]}"
            touch $SERVICE_PATH/done
          else
            echo "Comando inválido, argumentos insuficientes." | log error
          fi
        ;;
        setup_dns* )
          if ! [ -z "${args[1]}" ]; then
            run "$INSTALL_SCRIPTS_PATH/setup_dns.sh" "${args[1]}" "${args[2]}" "${args[3]}"
            touch $SERVICE_PATH/done
          else
            echo "Comando inválido, argumentos insuficientes." | log error
          fi
        ;;
        *)
          echo "O serviço recebeu um comando não suportado: $line" | log error
        ;;
      esac
  fi
}

main() {
  readFromPipe
}

if [[ ! -p $PIPE ]]; then
    mkfifo $PIPE
    chown avapolos:avapolos $PIPE
fi

echo "Daemon AVAPolos iniciado." | log info
echo "Rodando check incial automático." | log debug

check_services
update_moodle_hosts

while true; do
  main
done
