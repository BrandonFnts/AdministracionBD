-- Estrategias de backups
-- 1. Backups completos (full)
-- 2. Completos + diferenciales
-- 3. Completos + diferenciales + logs de transacciones

/* Plan de estrategias de backups */
-- Backup completo
backup database NorthWind
to disk = 'E:\linuxxx\backups\backupNorthWind.bak'
with name = 'Backup_Completo_03_03_2025',
description = 'Primer Backup Completo'
go

use NorthWind
go

-- Insertar registros
insert into Customers (CustomerID, CompanyName, country)
values ('ABCD3', 'Pecsi', 'USA'), ('ABCD4', 'Coca', 'Colombia')

select * from Customers
where CustomerID in ('ABCD3', 'ABCD4');

-- Backup Log
backup log NorthWind
to disk = 'E:\linuxxx\backups\backupNorthWind.bak'
with name = 'Backuplog1',
description = 'Log de 03/03/2025'
go

insert into Customers (CustomerID, CompanyName, country)
values ('ABCD5', 'Pumas', 'Mexico'), ('ABCD6', 'Cruz Azul', 'Saturno')

select * from Customers
where CustomerID in ('ABCD5', 'ABCD6');

-- Backup Diferencial
Backup database Northwind
to disk = 'E:\linuxxx\backups\backupNorthWind.bak'
with name = 'Backup_ Diferencial_03-03-2025',
description = 'Backup diferencial',
differential
go

-- Eliminamos
delete Customers where CustomerId in ('ABCD5','ABCD6')

insert into Customers (CustomerID, CompanyName, country)
values ('ABCD7', 'Cemex', 'Mexico'), ('ABCD8', 'Bimbo', 'Mexico')

-- Backup Log
backup log NorthWind
to disk = 'E:\linuxxx\backups\backupNorthWind.bak'
with name = 'Backuplog2',
description = 'Log de 04/03/2025'
go

-- Revisar el archivo .bak
restore headeronly
from disk = 'E:\linuxxx\backups\backupNorthWind.bak'

-- Eliminar la base de datos
use master

drop database Northwind
go

-- Restaurar el backup completo y los de logs

restore database Northwind
from disk = 'E:\linuxxx\backups\backupNorthWind.bak'
with file = 1, norecovery

restore log Northwind
from disk = 'E:\linuxxx\backups\backupNorthWind.bak'
with file = 2, recovery

restore log Northwind
from disk = 'E:\linuxxx\backups\backupNorthWind.bak'
with file = 4, recovery

-- Restaurar Completo y diferencial
restore database Northwind
from disk = 'E:\linuxxx\backups\backupNorthWind.bak'
with file = 1, norecovery

restore database Northwind
from disk = 'E:\linuxxx\backups\backupNorthWind.bak'
with file = 3, norecovery

use Northwind
go

select * from Customers
go