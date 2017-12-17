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

function checkNFSInstallation() {

    echo " - Comprobando instalación de paquetes requeridos"

    rpcbind_package="rpcbind"
    nfs_server_package="nfs-kernel-server"
    nfs_common_package="nfs-common"

    if dpkg -s $rpcbind_package > /dev/null 2>&1
    then
	echo " - - Paquete '$rpcbind_package' ya está instalado"
    else
	echo " - - Instalando '$rpcbind_package'..."
	apt-get -qq -y install $rpcbind_package 2>&1

	if dpkg -s $rpcbind_package > /dev/null 2>&1
	then
	    echo " - - Paquete '$rpcbind_package' instalado"
	else
	    exit 1
	fi
    fi

    if dpkg -s $nfs_common_package > /dev/null 2>&1
    then
        echo " - - Paquete '$nfs_common_package' ya está instalado"
    else
        echo " - - Instalando '$nfs_common_package'..."
        apt-get -qq -y install $nfs_common_package 2>&1

        if dpkg -s $nfs_common_package > /dev/null 2>&1
        then
            echo " - - Paquete '$nfs_common_package' instalado"
        else
            exit 1
        fi
    fi

    if dpkg -s $nfs_server_package > /dev/null 2>&1;
    then
	echo " - - Paquete '$nfs_server_package' ya está instalado"
    else
	echo " - - Instalando '$nfs_server_package'..."
	apt-get -qq -y install $nfs_server_package 2>&1

	if dpkg -s $nfs_server_package > /dev/null 2>&1
	then
	    echo " - - Paquete '$nfs_server_package' instalado"
	else
	    exit 1
	fi
    fi
}

function checkRequiredServers() {
    
    echo " - Comprobando activación de servidores requeridos"

    restart=false

    # Nfs
    if rpcinfo -u localhost nfs > /dev/null 2>&1
    then
	echo " - - Servidor 'nfs' activo"
    else
	echo " - - Servidor 'nfs' inactivo"
	restart=true
    fi

    # Portmapper|rpcbind
    if rpcinfo -u localhost portmapper > /dev/null 2>&1
    then
	echo " - - Servidor 'portmapper|rpcbind' activo"
    else
	echo " - - Servidor 'portmapper|rpcbind' inactivo"
	restart=true
    fi

    # Mountd
    if rpcinfo -u localhost mountd > /dev/null 2>&1
    then
	echo " - - Servidor 'mountd' activo"
    else
	echo " - - Servidor 'mountd' inactivo"
	restart=true
    fi

    # Nlockmgr
    if rpcinfo -u localhost nlockmgr | grep "ready and waiting" > /dev/null 2>&1
    then
	echo " - - Servidor 'nlockmgr' activo"
    else
	echo " - - Servidor 'nlockmgr' inactivo"
	restart=true
    fi

    if $restart
    then
	echo " - - Reiniciando portmapper|rpcbind..."
	service rpcbind restart > /dev/null 2>&1
	echo " - - Reiniciando nfs-common..."
	service nfs-common restart > /dev/null 2>&1
	echo " - - Reiniciando nfs-kernel-server..."
	service nfs-kernel-server restart > /dev/null 2>&1
    fi
} 

function exportPath() {
    echo " - Exportando '$1'"
    
    IFS=$'\n'
    IPs=($(ip -o -f inet addr show | awk '/scope global/ {print $4}'))
    unset IFS

    for ip in "${IPs[@]}"
        do
            exportLine="$path $ip(rw,sync,no_subtree_check)"
            exportFile="/etc/exports"
            if grep -q "$exportLine" $exportFile
	    then
		echo " - - Exportación de '$path' por $ip ya existe en '$exportFile'"
            else
                echo "$exportLine" >> $exportFile
		echo " - - Exportación de '$path' por $ip añadida a '$exportFile'"
            fi
        done
        echo " - - Aplicando exportaciones..."
        exportfs -ra > /dev/null 2>&1
}

function configureNFS() {
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

	IFS=' ' read path error <<< "$line"

	# Check number of parameters per line
	if [ ! -z $error ];
	then
            echo " - ERROR: Fichero de configuración. Se requiere la ruta del directorio a compartir como único parámetro. Línea $nL"
            exit 1
	fi

	# Check directory existance
	if [ ! -d $path ];
        then
            echo " - ERROR: El directorio '$path' no existe. Línea $nL"
            exit 1
	fi

	# Export path
	exportPath $path

    done < "$1"
}

#
# Running code
#

printf "\nComenzando configuración del servicio nfs_server\n"

checkParameters $@
checkNFSInstallation
checkRequiredServers
configureNFS $1

printf "\nFin de la configuración del servicio nfs_server\n"
exit 0