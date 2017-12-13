#!/bin/bash

#
# Functions
#

function checkParameters() {
    if [ $# -ne 1 ]
    then
        echo "$0: Error de uso. Se necesita fichero_configuracion unicamente"
        exit 1
    fi
}

function checkNFSInstallation() {
    nfs_package="nfs-common"

    if dpkg -s $nfs_package > /dev/null 2>&1;
    then
        echo "Nfs common ya está instalado"
    else
        echo "Instalando Nfs common..."
        apt-get -qq -y install $nfs_package 2>&1

        if dpkg -s $nfs_package > /dev/null 2>&1
        then
            echo "Nfs common instalado"
        else
            exit 1
        fi
    fi
}

function openNFSTraffic(){
    # FALTA ABRIR PUERTOS
}

function configureNFS() {
    nL=0
    while IFS='\n' read -r line || [[ -n "$line" ]];
    do
        nL=$((nL+1))

        # Check white line
        if [ -z ${line:0:1} ];
        then
            echo "Error linea $nL, Formato incorrecto, el fichero no puede contener líneas en blanco."
            exit 1
        fi

        IFS=' ' read ip remotePath localPath error <<< "$line"

        # Check number of parameters per line
        if [ ! -z $error ];
        then
            echo "Error línea $nL, Formato incorrecto, demasiados parámetros: $ip $remotePath $localPath $error"
            exit 1
        fi
	if [ -z $localPath ]
	then
	    echo "Error línea $nL, Formato incorrecto, faltan parámetros: $ip $remotePath $localPath $error"
	    exit 1
	fi

        # Check directory existance
        if [ ! -d $localPath ];
        then
            mkdir $localPath
        fi

	# Mount remote directory
	mount -t nfs $ip:$remotePath $localPath

	# Add auto-mount when system starts
	echo "$id:$remotePath $localPath nfs defaults" >> /etc/fstab

    done < "$1"
}

#
# Running code
#

printf "\n Comenzando configuración del servicio nfs_server \n"

checkParameters $@
checkNFSInstallation
openNFSTraffic
configureNFS $1

printf "\n Fin del programa \n"
exit 0