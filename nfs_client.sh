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

    if dpkg -s $nfs_common_package > /dev/null 2>&1;
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
}

function checkRequiredServices() {
    echo " - Comprobando activación de servicios requeridos"

    nfs_common_package="nfs-common"
    if service $nfs_common_package status > /dev/null 2>&1
    then
        echo " - - Servicio '$nfs_common_package' activado"
    else
        echo " - - Activando servicio '$nfs_common_package'..."
        service $nfs_common_package restart > /dev/null 2>&1
    fi
}

function checkValidHost() {
    if ! ping -c 1 $1 > /dev/null 2>&1
    then
	echo " - ERROR: El host '$1' no es válido"
	exit 1
    fi
}

function checkRequiredRemoteServers() {
    echo " - Comprobando alcance de servidores requeridos en $1"

    allFound=true
    
    # Nfs
    if rpcinfo -u $1 nfs > /dev/null 2>&1
    then
        echo " - - Servidor 'nfs' encontrado"
    else
        echo " - - ERROR: Servidor 'nfs' no encontrado"
        allFound=false
    fi

    # Portmapper|rpcbind
    if rpcinfo -u $1 portmapper > /dev/null 2>&1
    then
        echo " - - Servidor 'portmapper|rpcbind' encontrado"
    else
        echo " - - ERROR: Servidor 'portmapper|rpcbind' no encontrado"
        allFound=false
    fi

    # Mountd
    if rpcinfo -u $1 mountd > /dev/null 2>&1
    then
        echo " - - Servidor 'mountd' encontrado"
    else
        echo " - - ERROR: Servidor 'mountd' no encontrado"
        allFound=false
    fi

    # Nlockmgr
    if rpcinfo -u $1 nlockmgr | grep "ready and waiting" > /dev/null 2>&1
    then
        echo " - - Servidor 'nlockmgr' encontrado"
    else
        echo " - - ERROR: Servidor 'nlockmgr' no encontrado"
        allFound=false
    fi

    if ! $allFound
    then
	exit 1
    fi
}

function checkRequiredRemoteExportPath(){
    echo " - Comprobando exportación remota de '$1' en $2"

    if showmount -e $2 | grep "$1" > /dev/null 2>&1
    then
	echo " - - Exportación encontrada"
    else
	echo " - - ERROR: Exportación no encontrada"
	exit 1
    fi
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

        IFS=' ' read host remotePath localPath error <<< "$line"

        # Check number of parameters per line
        if [ ! -z $error ];
        then
            echo " - ERROR: Fichero de configuración. Demasiados parámetros. Solo se requiere el host, ruta remota y ruta local. Línea $nL"
            exit 1
        fi
	if [ -z $localPath ]
	then
	    echo " - ERROR: Fichero de configuración. Faltan parámetros. Se requiere el host, ruta remota y ruta local. Línea $nL"
	    exit 1
	fi

        # Check directory existance
        if [ ! -d $localPath ];
        then
            mkdir $localPath
	    echo " - Directorio '$localPath' creado"
        fi

	# Check valid host
	checkValidHost $host

	# Check remote servers
	checkRequiredRemoteServers $host

	# Check remote export
	checkRequiredRemoteExportPath $remotePath $host

	# Mount remote directory
	echo " - Montando $host:$remotePath en '$localPath'"
	mount -t nfs $host:$remotePath $localPath
	
	# Add nfs boot when system starts
	mountLine="$host:$remotePath $localPath nfs defaults"
	startFile="/etc/fstab"
	if ! grep -q "$mountLine" $startFile
	then
	    echo "$mountLine" >> $startFile
	    echo " - Arranque de nfs añadido al arranque del sistema"
	fi

    done < "$1"
}

#
# Running code
#

printf "\nComenzando configuración del servicio nfs_client\n"

checkParameters $@
checkNFSInstallation
checkRequiredServices
configureNFS $1

printf "\nFin de la configuración del servicio nfs_client\n"
exit 0