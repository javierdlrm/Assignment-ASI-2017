#!/bin/bash
if [ $# -ne 1 ]
then
	echo "$0: Error de uso. Se necesita fichero_configuracion unicamente"
	exit 1
fi

printf "\n Comenzando el raid \n"

nombre_dispos=`sed "1q;d" $1`
nivel=`sed "2q;d" $1`
dispositivos=`sed "3q;d" $1`
echo "$nombre_dispos de nivel $nivel en $dispositivos"
if [ -z $nombre_dispos ] || [ -z $nivel ] || [ -z ${dispositivos:0:1} ]; then 
	echo "Error en el archivo $1"
	exit 1
fi

#comprobar instalación de mdadm
#instalar mdadm si necesario
echo "Comprobando śi esta instalado mdadm:"
if dpkg -s "mdadm" > /dev/null 2>&1; then
	echo "mdadm ya está instalado"
else
	echo "mdadm no está instalado. Procediedo a instalacion" 
	apt-get -qq -y install mdadm #2>/dev/null
fi

sudo mdadm --create --level=$nivel -R --raid-devices=$(wc -w <<< "$dispositivos") $nombre_dispos $dispositivos && printf "\n Fin del script $1\n" exit 0 || exit 1
#PARA ELIMINAR raid en un futuro:
#sudo mdadm --stop /dev/md0 (O el nombre_dispos que se ha utilizado)
#sudo mdadm --remove /dev/md0 (O el nombre_dispos que se ha utilizado)