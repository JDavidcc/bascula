#   Báscula BLE Monitor

Aplicación desarrollada en Flutter para detectar y analizar paquetes Bluetooth Low Energy (BLE) provenientes de una báscula inteligente.

La app permite visualizar en tiempo real:

Peso detectado

Impedancia eléctrica

Métricas derivadas de bioimpedancia

Bytes crudos del paquete BLE

Monitor hexadecimal del paquete recibido

El objetivo del proyecto es analizar y comprender el protocolo BLE de la báscula sin documentación oficial, utilizando ingeniería inversa.

##  Vista de la aplicación

##  Características

Monitor BLE en tiempo real

La aplicación escanea dispositivos BLE cercanos y filtra por la MAC de la báscula.

**Visualización de peso**

El peso se decodifica directamente desde los primeros bytes del paquete BLE.

Ejemplo:

```dart
byte[0] = 47
byte[1] = 63
```

Conversión:

```
pesoRaw = (byte0 << 8) | byte1
pesoKg = pesoRaw / 100
```

Resultado:

```
120.95 kg
```
##  Lectura de impedancia
La impedancia eléctrica se obtiene de:
```
byte[6] y byte[7]
```
Conversión:
```
impedanciaRaw = (byte6 << 8) | byte7
impedancia = impedanciaRaw / 10
```
Ejemplo:
```
925 Ω
```

**Métricas experimentales**

Estas métricas se calculan únicamente para visualizar cambios en la bioimpedancia.

**Índice de Bioimpedancia**
```
BI = peso / impedancia
```
**Conductividad eléctrica**
```
conductividad = 1 / impedancia
```
**Índice corporal experimental**
```
indiceCorporal = (peso * 1000) / impedancia
```
##   Monitor de paquetes BLE

La app también muestra el paquete recibido completo:
```
00 00 00 00 00 00 24 24 16 51 9d de 4f
```
y cada byte individual:
```
Byte [0]  Decimal: 0   Hex: 0x00
Byte [1]  Decimal: 0   Hex: 0x00
Byte [2]  Decimal: 0   Hex: 0x00
...
```

Esto facilita analizar el protocolo de la báscula.

##  Tecnologías utilizadas

-   Flutter

-   Dart

-   Bluetooth Low Energy (BLE)

-   flutter_blue_plus

-   permission_handler

##  Permisos requeridos

Android requiere los siguientes permisos:
```
BLUETOOTH_SCAN
BLUETOOTH_CONNECT
ACCESS_FINE_LOCATION
```
##  Instalación

Clonar repositorio
```
git clone https://github.com/tu_usuario/bascula-ble-monitor.git
```
Entrar al proyecto
```
cd bascula-ble-monitor
```
Instalar dependencias
```
flutter pub get
```
Ejecutar
```
flutter run
```
##  Estructura del paquete BLE
Ejemplo de paquete:
```
[47, 63, 23, 112, 0, 0, 37, 36, 22, 81, 157, 222, 79]
```
Byte	Significado
0-1	Peso
2-5	Flags / datos desconocidos
6-7	Impedancia
8-12	Dirección MAC
##  Propósito del proyecto

-   Este proyecto fue desarrollado para:

-   experimentar con BLE

-   analizar protocolos propietarios

-   construir herramientas de debug en Flutter

-   explorar aplicaciones de bioimpedancia