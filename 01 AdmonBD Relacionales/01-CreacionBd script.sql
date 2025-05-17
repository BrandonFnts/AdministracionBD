-- Creaci�n de la base de datos 'paquitabd'
CREATE DATABASE paquitabd
ON PRIMARY
(
    Name = paquitabdData,              -- Nombre l�gico del archivo de datos
    filename = 'E:\linuxxx\example\data-nueva\paquitabd.mdf', -- Ruta f�sica del archivo .mdf
    size = 50MB,                        -- Tama�o inicial del archivo
    filegrowth = 25%,                   -- Crecimiento autom�tico (25%)
    maxsize = 400MB                     -- Tama�o m�ximo del archivo
)
LOG ON 
(
    Name = paquitabdLog,                -- Nombre l�gico del archivo de registro
    filename = 'E:\linuxxx\example\log-nueva\paquita_log.ldf', -- Ruta f�sica del archivo .ldf
    size = 25MB,                        -- Tama�o inicial del archivo
    filegrowth = 25%                    -- Crecimiento autom�tico (25%)
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

-- Creaci�n de un archivo asociado al filegroup
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

-- Revision del estado de la opci�n de ajuste automatico del tama�o de archivos

select databasepropertyex('paquitabd', 'isautoshrink');

-- Cambia la opci�n de autoreducci�n a true
alter database paquitabd
set auto_shrink on with no_wait;

-- Revision del estado de la opci�n de creci�n de estadisticas

select DATABASEPROPERTYEX('paquitabd', 'isAutoCreateStatistics');

-- Cambia la opci�n de estadisticas a true
alter database paquitabd
set auto_create_statistics on;

-- Consultar informaci�n de la base de datos
use master
go
sp_helpdb paquitabd;

-- Consultar informaci�n de los grupos
use paquitabd
go

sp_helpfilegroup secundario;

CREATE PROCEDURE CreateCustomDatabase
    @dbname sysname,                -- Nombre de la base de datos
    @datafilename nvarchar(260),   -- Ruta completa del archivo de datos (.mdf)
    @datasizeMB int,                -- Tama�o inicial del archivo de datos (MB)
    @datafilegrowthMB int = NULL,   -- Crecimiento del archivo de datos en MB (opcional)
    @datafilegrowthPercent int = NULL, -- Crecimiento del archivo de datos en porcentaje (opcional)
    @logfilename nvarchar(260),     -- Ruta completa del archivo de log (.ldf)
    @logsizeMB int,                 -- Tama�o inicial del archivo de log (MB)
    @logfilegrowthMB int = NULL,    -- Crecimiento del archivo de log en MB (opcional)
    @logfilegrowthPercent int = NULL -- Crecimiento del archivo de log en porcentaje (opcional)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validaci�n de par�metros
        IF @dbname IS NULL OR @datafilename IS NULL OR @logfilename IS NULL
        BEGIN
            RAISERROR('El nombre de la base de datos y las rutas de los archivos son obligatorios.', 16, 1);
            RETURN;
        END

        IF @datasizeMB <= 0 OR @logsizeMB <= 0
        BEGIN
            RAISERROR('El tama�o inicial de los archivos debe ser mayor que 0.', 16, 1);
            RETURN;
        END

        IF (@datafilegrowthMB IS NULL AND @datafilegrowthPercent IS NULL) OR
           (@logfilegrowthMB IS NULL AND @logfilegrowthPercent IS NULL)
        BEGIN
            RAISERROR('Debe especificar el crecimiento del archivo de datos y log en MB o porcentaje.', 16, 1);
            RETURN;
        END

        -- Construir el comando SQL din�mico
        DECLARE @sql nvarchar(max);

        SET @sql = 
            N'CREATE DATABASE ' + QUOTENAME(@dbname) + N' ' +
            N'ON PRIMARY ' +
            N'( ' +
            N'    NAME = ' + QUOTENAME(@dbname + N'_Data') + N', ' + -- Nombre l�gico del archivo de datos
            N'    FILENAME = ''' + @datafilename + N''', ' +
            N'    SIZE = ' + CAST(@datasizeMB AS nvarchar) + N'MB, ' +
            CASE 
                WHEN @datafilegrowthMB IS NOT NULL THEN N'    FILEGROWTH = ' + CAST(@datafilegrowthMB AS nvarchar) + N'MB '
                ELSE N'    FILEGROWTH = ' + CAST(@datafilegrowthPercent AS nvarchar) + N'% '
            END +
            N') ' +
            N'LOG ON ' +
            N'( ' +
            N'    NAME = ' + QUOTENAME(@dbname + N'_Log') + N', ' + -- Nombre l�gico del archivo de log
            N'    FILENAME = ''' + @logfilename + N''', ' +
            N'    SIZE = ' + CAST(@logsizeMB AS nvarchar) + N'MB, ' +
            CASE 
                WHEN @logfilegrowthMB IS NOT NULL THEN N'    FILEGROWTH = ' + CAST(@logfilegrowthMB AS nvarchar) + N'MB '
                ELSE N'    FILEGROWTH = ' + CAST(@logfilegrowthPercent AS nvarchar) + N'% '
            END +
            N');';

        -- Ejecutar el comando
        EXEC sp_executesql @sql;

    END TRY
    BEGIN CATCH
        -- Manejo de errores
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;

EXEC CreateCustomDatabase
    @dbname = 'BrandonDb',
    @datafilename = 'E:\linuxxx\sp\data\paquitabd.mdf',
    @logfilename = 'E:\linuxxx\sp\log\paquita_log.ldf',
    @datasizeMB = 50,         -- Tama�o inicial del archivo de datos: 50MB
    @logsizeMB = 25,          -- Tama�o inicial del log: 25MB
    @filegrowthPercent = 25,  -- Crecimiento autom�tico del 25%
    @maxsizeMB = 400;         -- Tama�o m�ximo del archivo de datos: 400MB