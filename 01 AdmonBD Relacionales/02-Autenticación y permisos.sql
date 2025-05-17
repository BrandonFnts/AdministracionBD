-- Crear un loginde sql, este login da acceso al servidor

use master
go

-- Login con autenticación SQL
create login DevelopmentUser with password='123456'
go

-- Login con autenticación de windows
--create login 'brangd\serverbd' with password=windows
--go

-- Crear un usuario asociado al login y mapeando una bd
use paquitabd;
create user DevelopmentUser for login DevelopmentUser
with default_schema = informatica
go

create schema informatica
authorization DevelopmentUser
go

--Permiso para crear tablas
grant create table to DevelopmentUser

-- Permiso de select a todas las tablas
grant select to DevelopmentUser

-- Permiso de eliminar a todas las tablas
grant delete to DevelopmentUser

deny delete to DevelopmentUser

revoke create table to DevelompentUser

-- Permisos por tabla
revoke select to Development
grant select on orders to DevelopmentUser
grant select(shipcity) on orders to DevelopmentUser

ALTER PROCEDURE ManageDatabaseSecurity
    @LoginName NVARCHAR(128),
    @Password NVARCHAR(128), -- Nuevo parámetro
    @UserName NVARCHAR(128),
    @DatabaseName NVARCHAR(128),
    @TablesPermissions NVARCHAR(MAX) = NULL,
    @SchemasPermissions NVARCHAR(MAX) = NULL,
    @RolesMembership NVARCHAR(MAX) = NULL,
    @CreateRoles NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID INT;

    BEGIN TRY
        -- Registrar inicio en LogSP (fuera de la transacción)
        INSERT INTO AdminTools.dbo.LogSP (
            Fecha, 
            SPName, 
            Parametros, 
            Usuario, 
            Estado
        ) VALUES (
            GETDATE(), 
            'ManageDatabaseSecurity', 
            CONCAT(
                'Login: ', @LoginName,
                ', User: ', @UserName,
                ', Database: ', @DatabaseName
            ), 
            SUSER_NAME(), 
            'Iniciado'
        );

        SET @LogID = SCOPE_IDENTITY();

        -- Validación de parámetros obligatorios
        IF @LoginName IS NULL OR @UserName IS NULL OR @DatabaseName IS NULL
        BEGIN
            UPDATE AdminTools.dbo.LogSP 
            SET Estado = 'Fallido', 
                MensajeError = 'Parámetros obligatorios faltantes'
            WHERE ID = @LogID;
            RAISERROR('Parámetros obligatorios faltantes', 16, 1);
            RETURN;
        END

        BEGIN TRANSACTION;

        -- 1. Crear Login si no existe
        IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @LoginName)
        BEGIN
            DECLARE @CreateLoginSQL NVARCHAR(MAX) = 
                N'CREATE LOGIN ' + QUOTENAME(@LoginName) + 
                N' WITH PASSWORD = N''' + @Password + N''', ' +
                N'CHECK_POLICY = OFF;';

            EXEC sp_executesql @CreateLoginSQL;
            PRINT 'Login creado: ' + @LoginName;
        END

        -- 2. Crear Usuario en la base de datos
        DECLARE @CreateUserSQL NVARCHAR(MAX) = 
            N'USE ' + QUOTENAME(@DatabaseName) + N'; 
            IF NOT EXISTS (
                SELECT 1 
                FROM sys.database_principals 
                WHERE name = @UserName
            )
            CREATE USER ' + QUOTENAME(@UserName) + 
            N' FOR LOGIN ' + QUOTENAME(@LoginName) + N';';

        EXEC sp_executesql @CreateUserSQL, N'@UserName NVARCHAR(128)', @UserName;

        -- 3. Función alternativa para split (si se usa versión < 2016)
        IF OBJECT_ID('dbo.SplitString') IS NULL
        BEGIN
            EXEC('CREATE FUNCTION dbo.SplitString(@List NVARCHAR(MAX), @Delimiter CHAR(1))
            RETURNS @Items TABLE (Item NVARCHAR(4000))
            AS
            BEGIN
                DECLARE @StartPos INT, @EndPos INT
                SET @StartPos = 1
                IF SUBSTRING(@List, LEN(@List), 1) <> @Delimiter
                    SET @List = @List + @Delimiter
                WHILE CHARINDEX(@Delimiter, @List, @StartPos) <> 0
                BEGIN
                    SET @EndPos = CHARINDEX(@Delimiter, @List, @StartPos)
                    INSERT INTO @Items (Item)
                    VALUES (SUBSTRING(@List, @StartPos, @EndPos - @StartPos))
                    SET @StartPos = @EndPos + 1
                END
                RETURN
            END');
        END

        -- 4. Procesar permisos de tablas
        IF @TablesPermissions IS NOT NULL
        BEGIN
            DECLARE @TablePermissions TABLE (
                ID INT IDENTITY(1,1),
                ObjectName NVARCHAR(512),
                Permissions NVARCHAR(256)
            );

            INSERT INTO @TablePermissions (ObjectName, Permissions)
            SELECT 
                LEFT(Item, CHARINDEX(':', Item) - 1),
                SUBSTRING(Item, CHARINDEX(':', Item) + 1, LEN(Item))
            FROM dbo.SplitString(@TablesPermissions, ';');

            DECLARE @CurrentTableID INT = 1,
                    @TotalTables INT = (SELECT COUNT(*) FROM @TablePermissions),
                    @CurrentObject NVARCHAR(512),
                    @CurrentPerms NVARCHAR(256);

            WHILE @CurrentTableID <= @TotalTables
            BEGIN
                SELECT @CurrentObject = ObjectName,
                       @CurrentPerms = Permissions
                FROM @TablePermissions
                WHERE ID = @CurrentTableID;

                SET @SQL = N'USE ' + QUOTENAME(@DatabaseName) + N';
                    GRANT ' + @CurrentPerms + N' ON ' + 
                    QUOTENAME(PARSENAME(@CurrentObject, 2)) + N'.' + 
                    QUOTENAME(PARSENAME(@CurrentObject, 1)) + 
                    N' TO ' + QUOTENAME(@UserName) + N';';

                EXEC sp_executesql @SQL;
                SET @CurrentTableID += 1;
            END
        END

        -- 5. Procesar permisos de esquemas (similar a tablas)
        -- ... (implementación similar usando la función SplitString)

        -- 6. Procesar roles
        IF @RolesMembership IS NOT NULL
        BEGIN
            DECLARE @Roles TABLE (ID INT IDENTITY(1,1), RoleName NVARCHAR(128));
            INSERT INTO @Roles (RoleName)
            SELECT Item FROM dbo.SplitString(@RolesMembership, ',');

            DECLARE @CurrentRoleID INT = 1,
                    @TotalRoles INT = (SELECT COUNT(*) FROM @Roles),
                    @CurrentRole NVARCHAR(128);

            WHILE @CurrentRoleID <= @TotalRoles
            BEGIN
                SELECT @CurrentRole = RoleName
                FROM @Roles
                WHERE ID = @CurrentRoleID;

                SET @SQL = N'USE ' + QUOTENAME(@DatabaseName) + N';
                    ALTER ROLE ' + QUOTENAME(@CurrentRole) + 
                    N' ADD MEMBER ' + QUOTENAME(@UserName) + N';';

                BEGIN TRY
                    EXEC sp_executesql @SQL;
                END TRY
                BEGIN CATCH
                    PRINT 'Error asignando al rol: ' + @CurrentRole;
                END CATCH

                SET @CurrentRoleID += 1;
            END
        END

        COMMIT TRANSACTION;

        -- Actualizar log después de transacción exitosa
        UPDATE AdminTools.dbo.LogSP 
        SET Estado = 'Exitoso', 
            FechaFin = GETDATE()
        WHERE ID = @LogID;

    END TRY
    BEGIN CATCH
        -- Manejar rollback y registro de error
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        UPDATE AdminTools.dbo.LogSP 
        SET Estado = 'Fallido', 
            MensajeError = ERROR_MESSAGE(), 
            FechaFin = GETDATE()
        WHERE ID = @LogID;

        RAISERROR('Error en ManageDatabaseSecurity: %s', 16, 1, ERROR_MESSAGE());
    END CATCH;
END;


EXEC ManageDatabaseSecurity 
    @LoginName = 'Operador1',
    @UserName = 'UsuarioBD',
    @DatabaseName = 'ErickExamen',
    @TablesPermissions = 'dbo.AutorLibro:SELECT,INSERT;dbo.AutorLibro:UPDATE',
    @RolesMembership = 'db_datareader,db_datawriter';

use ErickExamen
go

select * from AutorLibro
go

delete from AutorLibro where AutorLibroId = 1
go