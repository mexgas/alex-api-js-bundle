

USE CCenterRIA

SELECT * from ccCampsExtend 

-- 1. Primero eliminamos la restricción (el objeto dependiente)
ALTER TABLE ccCampsExtend 
DROP CONSTRAINT DF_ccCampsExtend_zipCodeSchedule;
GO

-- 2. Ahora sí podemos eliminar la columna sin errores
ALTER TABLE ccCampsExtend 
DROP COLUMN zipCodeSchedule;
GO

