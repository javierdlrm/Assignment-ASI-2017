#!/bin/bash
if [ $# -ne 1 ]
then
	echo "$0: Error de uso. Se necesita fichero_configuracion unicamente"
	exit 1
fi

#sed 'NUMq;d' file
nombre_dominio=`sed "1q;d" $1`
ip_servidor=`sed "2q;d" $1`
aux=`awk 'NR>2' $1`

#Comprobamos formato del .conf
if [ -z $nombre_dominio ] || [ -z $ip_servidor ] ||[ -z ${ip_servidor:0:1} ]; then 
	echo "Error en el archivo $1"
	exit 1
fi

#Comprobamos valores y formato válido para la IP
value=1
if [[ $ip_servidor =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip_servidor)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    value=$?
    #echo $value
fi
if [ $value -eq 0 ]; then
	echo "Formato de IP válida"
else 
	echo "Error en el formato de IP"
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
echo "Configurando los archivos para que sea un cliente"
cp /etc/default/nis nis.temp
sed -i -e 's/NISSERVER=true/NISSERVER=false/' nis.temp
sed -i -e 's/NISCLIENT=false/NISCLIENT=true/' nis.temp
mv nis.temp /etc/default/nis

#Agregar la linea de configuración del servidor
echo "Ajustando los datos del servidor en archivo de configuración"
cp /etc/yp.conf yp.temp
if ! grep "domain $nombre_dominio server $ip_servidor" yp.temp > /dev/null; then 
	echo "domain $nombre_dominio server $ip_servidor" >> yp.temp
fi
mv yp.temp /etc/yp.conf

#Añadimos los parametros de configuración necesarios
echo "Cambiamos los datos del nsswitch.conf"
cp /etc/nsswitch.conf nss.temp
if ! grep -w "compat nis" nss.temp > /dev/null; then 
	sed -i -e 's/compat/compat nis/' nss.temp
	sed -i -e '/^hosts:/ s/$/ nis/' nss.temp 
	#con este formato es como un "append"
fi
mv nss.temp /etc/nsswitch.conf

echo "Reseteamos el servicio NIS"

#/usr/lib/yp/ypinit -m
/etc/init.d/nis restart
#echo "$0 $1"
exit 0