-- Backup Completo

backup database AdventureWorksDW2017
to disk = 'E:\linuxxx\backups\backupAdventure.bak'
with name = 'Backupcompleto_03_03_2025',
description = 'Backup completo de adventure works'
go

-- Backup diferencial
backup database AdventureWorksDW2017
to disk = 'E:\linuxxx\backups\backupAdventure.bak'
with name = 'Backupdiferencial1_04_03_2025',
description = 'Backup diferencial 1 de nAdventure works',
differential
go

-- Backup de log de transacciones
backup log AdventureWorksDW2017
to disk = 'E:\linuxxx\backups\backupAdventure.bak'
with name = 'Backuplog1',
description = 'Backup de transacciones 1 de Adventure works'
go

-- Backup solo copia
backup database AdventureWorksDW2017
to disk = 'E:\linuxxx\backups\backupAdventure.bak'
with copy_only,
name = 'Backupsolocopia',
description = 'Backup de solo copia de la base de datos'
go

-- Backup de filegroup ( Parciales )
Backup database AdventureWorksDW2017
filegroup = 'Primary'
to disk = 'E:\linuxxx\backups\backupAdventure.bak'
with name = 'Backupfilegroupprimary'
go

-- Backup de la cola de log
backup log AdventureWorksDW2017
to disk = 'E:\linuxxx\backups\backupAdventure.bak'
with recovery, 
name = 'Backup_cola_log1',
description = 'Backup de cola de log de Adventure works'
go