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

    # Check number of lines in configuration file
    if [[ $(sed -n '$=' $1) -ne 4 ]]
    then
        echo " - ERROR: Fichero de configuración. El fichero tiene que contener exactamente cuatro líneas."
        exit 1
    fi

    # Check parameters
    localPath=$(sed -n 1p $1);
    host=$(sed -n 2p $1);
    remotePath=$(sed -n 3p $1);
    hours=$(sed -n 4p $1);

    if [ -z $localPath ]
    then
        echo " - ERROR: Fichero de configuración. No puede haber líneas en blanco. Línea 1. Escriba aquí la ruta local"
        exit 1
    fi
    if [ -z $host ]
    then
	echo " - ERROR: Fichero de configuración. No puede haber líneas en blanco. Línea 2. Escriba aquí el host"
	exit 1
    fi
    if [ -z $remotePath ]
    then
	echo " - ERROR: Fichero de configuración. No puede haber líneas en blanco. Línea 3. Escriba aquí la ruta remota"
	exit 1
    fi
    if [ -z $hours ]
    then
	echo " - ERROR: Fichero de configuración. No puede haber líneas en blanco. Línea 4. Escriba aquí la periodicidad en horas"
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
    crontabLine="0 0/$hours 0 0 0 $rsyncCommand"
    crontabFile="/etc/crontab"
    if ! grep -q "$crontabLine" $crontabFile
    then
	echo "$crontabLine" >> $crontabFile
	echo " - Periodicidad configurada cada $hours horas"
    fi
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