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
    nfs_package="nfs-kernel-server"

    if dpkg -s $nfs_package > /dev/null 2>&1;
    then
	echo "Nfs server ya está instalado"
    else
	echo "Instalando Nfs server..."
	apt-get -qq -y install $nfs_package 2>&1

	if dpkg -s $nfs_package > /dev/null 2>&1
	then
	    echo "Nfs server instalado"
	else
	    exit 1
	fi
    fi
}

function checkRequiredServers(){
    
    # Rpcbind
    if rpcinfo -p | grep "rpcbind"
    then
	echo "Servidor 'rpcbind' activo"
    else
	echo "Servidor 'rpcbind' inactivo"
	exit 1
    fi

    # Mountd
    if rpcinfo -p | grep "mountd"
    then
	echo "Servidor 'mountd' activo"
    else
	echo "Servidor 'mountd' inactivo"
	exit 1
    fi

    # Lockd
    if rpcinfo -p | grep "lockd"
    then
	echo "Servidor 'lockd' activo"
    else
	echo "Servidor 'lockd' inactivo"
	exit 1
    fi

    # Statd
    if rpcinfo -p | grep "statd"
    then
	echo "Servidor 'statd' activo"
    else
	echo "Servidor 'statd' inactivo"
	exit 1
    fi

    # Rquotad
    if rpcinfo -p | grep "rquotad"
    then
	echo "Servidor 'rquotad' activo"
    else
	echo "Servidor 'rquotad' inactivo"
	exit 1
    fi
} 

function configureNFS() {

    nL=0
    IPs=($(ip -o -f inet addr show | awk '/scope global/ {print $4}'))

    while IFS='\n' read -r line || [[ -n "$line" ]];
    do
	nL=$((nL+1))

	# Check white line
	if [ -z ${line:0:1} ];
	then
            echo "Error linea $nL, Formato incorrecto, el fichero no puede contener líneas en blanco."
            exit 1
	fi

	IFS=' ' read path error <<< "$line"

	# Check number of parameters per line
	if [ ! -z $error ];
	then
            echo "Error línea $nL, Formato incorrecto, demasiados parámetros, solo se requiere la ruta del directorio a compartir"
            exit 1
	fi

	# Check directory existance
	if [ ! -d $path ];
        then
            echo "Error línea $nL, Formato incorrecto, el directorio $path no existe"
            exit 1
	fi

	# Export path
	for $ip in $IPs
	do
    	    echo "$path $ip(rw,sync)" >> /etc/exports
	done
	exportfs -ra

    done < "$1"
}

#
# Running code
#

printf "\n Comenzando configuración del servicio nfs_server \n"

checkParameters $@
checkNFSInstallation
checkRequiredServers
configureNFS $1

printf "\n Fin del programa \n"
exit 0
