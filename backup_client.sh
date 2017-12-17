#!/bin/bash

#
# Functions
#

function checkParameters() {
   if [ $# -ne 1 ]
    then
        echo " - ERROR: Se necesita un fichero de configuración únicamente"
        exit 1
    fi
}

function checkRsyncInstallation() {

    echo " - Comprobando instalación de paquetes requeridos"

    rsync_package="rsync"

    if dpkg -s $rsync_package > /dev/null 2>&1
    then
        echo " - - Paquete '$rsync_package' ya está instalado"
    else
        echo " - - Instalando '$rsync_package'..."
        apt-get -qq -y install $rsync_package 2>&1

        if dpkg -s $rsync_package > /dev/null 2>&1
        then
            echo " - - Paquete '$rsync_package' instalado"
        else
	    echo " - - ERROR: No se pudo instalar el paquete '$rsync_package'"
            exit 1
        fi
    fi
}

function checkValidHost() {
    if ! ping -c 1 $1 > /dev/null 2>&1
    then
        echo " - ERROR: El host '$1' no es válido"
        exit 1
    fi
}

function configureBackupClient() {
    nL=0
    while IFS='\n' read -r line || [[ -n "$line" ]];
    do
        nL=$((nL+1))

        # Check white line
        if [ -z ${line:0:1} ];
        then
            echo " - ERROR: Fichero de configuración. No puede haber líneas en blanco. Línea $nL"
            exit 1
        fi

        IFS=' ' read localPath host remotePath hours error <<< "$line"

        # Check number of parameters per line
        if [ ! -z $error ];
        then
            echo " - ERROR: Fichero de configuración. Demasiados parámetros. Solo se requiere la ruta local, el host, la ruta remota y la periodicidad. Línea $nL"
            exit 1
        fi
        if [ -z $hours ]
        then
            echo " - ERROR: Fichero de configuración. Faltan parámetros. Se requiere la ruta local, el host, la ruta remota y la periodicidad. Línea $nL"
            exit 1
        fi

	# Check directory existance
	if [ ! -d $localPath ]
	then
            echo " - ERROR: El directorio '$localPath' no existe"
            exit 1
	fi

	# Check valid host
	checkValidHost $host

	# Check remote directory existance
	if ssh $host stat $remotePath > /dev/null 2>&1
	then
	    echo " - El directorio remoto existe"
	else
	    echo " - ERROR: El directorio remoto '$remotePath' no existe"
	    exit 1
	fi

	# Check remote directory permissions
	# FALTA
	echo " - Permisos de escritura activados en el directorio remoto"

	# Configure rsync
	echo " - Configurando rsync..."
	rsyncCommand="rsync --recursive $localPath $host:$remotePath/"
	$rsyncCommand > /dev/null 2>&1

	# Configure crontab
	crontabLine="0 0 0 0 0 $rsyncCommand"
	crontabFile="/etc/crontab"
	if ! grep -q "$crontabLine" $crontabFile
	then
	    echo "$crontabLine" >> $crontabFile
	    echo " - Periodicidad configurada cada $hours horas"
	fi
       
    done < "$1"
}

#
# Running code
#

printf "\nComenzando configuración del servicio backup_client\n"

checkParameters $@
checkRsyncInstallation
configureBackupClient $1

printf "\nFin de la configuración del servicio backup_client\n"
exit 0