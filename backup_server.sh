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

function configureBackupServer() {

    # Check number of lines in configuration file
    if [[ $(wc -l <$1) -ne 1 ]]
    then
	echo " - ERROR: Fichero de configuración. No puede haber más de una línea"
	exit 1
    fi

    IFS=' ' read path error
    
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
configureBackupServer $1

printf "\nFin de la configuración del servicio backup_server\n"
exit 0