#!/bin/bash
if [ $# -ne 1 ]
then
	echo "$0: Error de uso. Se necesita fichero_configuracion unicamente"
	exit 1
fi

#sed 'NUMq;d' file
nombre_dominio=`sed "1q;d" $1`
aux=`awk 'NR>2' $1`

#Comprobamos formato del .conf
if [ -z $nombre_dominio ] || [ -z ${nombre_dominio:0:1} ]; then 
	echo "Error en el archivo $1"
	exit 1
fi

#Instalar nis si necesario
echo "Comprobamos si el paquete está instalado"
if dpkg -s "nis" > /dev/null 2>&1; then
	echo "	nis ya está instalado"
else
	echo "	nis no está instalado" 
	apt-get update #he puesto esto porque si no nos daba error cuando intentabamos hacer el install
	apt-get -qq -y install nis >/dev/null
fi
#ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'

#Cambiando el archivo de dominios (para añadir el nuestro)
echo "Comprobamos si está el dominio en el archivo"
if grep -w $nombre_dominio /etc/defaultdomain > /dev/null; then 
  echo "	Ya está el dominio en el archivo"
else 
  echo "	No está, añadirlo"
  linea="$nombre_dominio"
  echo "$linea" >> /etc/defaultdomain
fi

#Cambiamos la configuración para que sea un server
#sed -i -e '(nºlinea)s/(patron_a_buscar)/(sustitución)/' (archivo)
echo "Configurando los archivos para que sea un servidor"
cp /etc/default/nis nis.temp
sed -i -e 's/NISSERVER=false/NISSERVER=master/' nis.temp
sed -i -e 's/NISCLIENT=true/NISCLIENT=false/' nis.temp
mv nis.temp /etc/default/nis

echo "Reseteamos el servicio NIS"

#Hacemos a este servidor el maestro
/usr/lib/yp/ypinit -m
/etc/init.d/nis restart
#echo "$0 $1"
exit 0