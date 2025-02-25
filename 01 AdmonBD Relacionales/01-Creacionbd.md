# Creación de base de datos

```
SQL
-- Creación de la base de datos 'paquitabd'
CREATE DATABASE paquitabd
ON PRIMARY
(
    Name = paquitabdData,              -- Nombre lógico del archivo de datos
    filename = 'E:\linuxxx\example\data-nueva\paquitabd.mdf', -- Ruta física del archivo .mdf
    size = 50MB,                        -- Tamaño inicial del archivo
    filegrowth = 25%,                   -- Crecimiento automático (25%)
    maxsize = 400MB                     -- Tamaño máximo del archivo
)
LOG ON 
(
    Name = paquitabdLog,                -- Nombre lógico del archivo de registro
    filename = 'E:\linuxxx\example\log-nueva\paquita_log.ldf', -- Ruta física del archivo .ldf
    size = 25MB,                        -- Tamaño inicial del archivo
    filegrowth = 25%                    -- Crecimiento automático (25%)
);

-- Crear Archivo Adicional
alter database paquitabd
add file
(
	name = 'PaquitaDataNdf'
	,filename = 'E:\linuxxx\example\data-nueva\paquitabd2.ndf'
	,size = 25MB
	,maxsize = 500MB
	,filegrowth = 10MB -- El minimo es de 1MB
) to filegroup[PRIMARY];

-- Creacion de un filegroup adicional
alter database paquitabd
add filegroup secundario;

-- Creación de un archivo asociado al filegroup
alter database paquitabd
add file 
(
	name = 'paquitabd_parte1'
	,filename = 'E:\linuxxx\example\data-nueva\paquitabd_secundario.ndf'
) to filegroup secundario;

-- Crear una tabla en el grupo de archivos secundario
use paquitabd;

create table ratadedospatas(
	id int not null identity(1,1),
	nombre nvarchar(100) not null,
	constraint pk_ratadedospatas primary key (id),
	constraint unico_nombre unique(nombre)
) on secundario -- especificamos el grupo de archivos

-- Modificar el grupo primario
use paquitabd;

create table animalrastrero(
	id int not null identity(1,1),
	nombre nvarchar(100) not null,
	constraint pk_animalrastrero primary key (id),
	constraint unico_nombre2 unique(nombre)
)

-- Modificar el grupo primario

use master;

alter database paquitabd
modify filegroup [secundario] default;

use paquitabd;

create table comparadocontigo(
	id int not null identity(1,1),
	nombredelanimal nvarchar(100) not null,
	defectos nvarchar(max) not null
	constraint pk_comparadocontigo primary key (id),
	constraint unico_nombre3 unique(nombredelanimal)
);
```