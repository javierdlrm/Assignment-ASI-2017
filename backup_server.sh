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

function configureBackupServer() {

    # Check number of lines in configuration file
    if [[ $(sed -n '$=' $1) -ne 1 ]]
    then
	echo " - ERROR: Fichero de configuración. El fichero tiene que contener exactamente una línea."
	exit 1
    fi

    IFS=' ' read path error <<< "$(head -n 1 $1)"
    
    # Check number of parameters per line
    if [ ! -z $error ]
    then
	echo " - ERROR: Fichero de configuración. Demasiados parámetros. Solo se requiere la ruta de backup"
	exit 1
    fi

    # Check directory existance
    if [ ! -d $path ]
    then
	echo " - ERROR: El directorio '$path' no existe"
	exit 1
    fi

    # Check empty directory
    if [ -n "$(ls -A $path)" ]
    then
	echo " - ERROR: El directorio '$path' no está vacío"
	exit 1
    fi

    
}

#
# Running code
#

printf "\nComenzando configuración del servicio backup_server\n"

checkParameters $@
checkRsyncInstallation
configureBackupServer $1

printf "\nFin de la configuración del servicio backup_server\n"
exit 0