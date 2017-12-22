#!/bin/bash

if [ $# -ne 1 ]
then
	echo "$0: Error de uso. Se necesita fichero_configuracion unicamente"
	exit 1
fi

printf "Comenzando el lvm \n"

#sed 'NUMq;d' file
nombre_grupo=`sed "1q;d" $1`
dispositivos=`sed "2q;d" $1`
vLogico=`awk 'NR>2' $1`

if [ -z $nombre_grupo ] || [ -z ${dispositivos:0:1} ]; then 
	echo "Error en el archivo $1"
	exit 1
fi

echo "Comprobando śi esta instalado lvm2"
if dpkg -s "lvm2" > /dev/null 2>&1; then
	echo "lvm ya está instalado"
else
	echo "lvm no está instalado. Procedemos a su instalacion" 
	apt-get -qq -y install lvm2 #2>/dev/null
fi


#Creacion de volumenes fisicos. exit 1 si el dispositivo ya pertenece a un grupo
echo "Inicializamos los volumnes fısicos"
sudo pvcreate $dispositivos > /dev/null 2>&1 || { echo "Error al crear los volumenes fisicos"; exit 1; }

#Creacion del grupo. exit 1 si el grupo ya esta creado con otros dispositivos
echo "Creamos el grupo $nombre_grupo"
sudo vgcreate $nombre_grupo $dispositivos > /dev/null 2>&1 || { echo "Error al crear el grupo"; exit 1; }

if [ -z ${vLogico:0:1} ] ; then 
	echo "Es necesario al menos un volumen logico para crear"
	exit 1
fi

nL=2
while IFS='\n' read -r line || [[ -n "$line" ]]; do
	nL=$((nL+1))
	IFS=' ' read name size <<< $line
	if [ -z $name ] || [ -z $size ] ; then #Es necesario un nombre y un tamaño
		echo "Linea $nL $1: Se espera un nombre y un tamaño"
		exit 1
	fi
	echo "Crearemos el volumnes logicos $name con nuestros dispositivos"
	sudo lvcreate --name $name --size $size $nombre_grupo > /dev/null 2>&1 || { echo "Error al crear el grupo logico."; exit 1; }
done <<< "$vLogico"

printf "\n Fin del script $1\n"
exit 0 
#Si se quiere eliminar / Ver informacion
#lvremove $name 	   / lvdisplay
#vgremove $name		   / vgdisplay
#pvremove $name 	   / pvdisplay