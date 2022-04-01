

EXEC sys.sp_addextendedproperty 
@name=N'Description', 
@value=N'Identificador del grupo de trabajo, referirse a ccRIACat_WorkGroup' , 
@level0type=N'SCHEMA',
@level0name=N'dbo', 
@level1type=N'TABLE',
@level1name=N'ccRIAWorkGroupUsers', 
@level2type=N'COLUMN',
@level2name=N'IDWG'
GO
SELECT objtype, objname, name, value
FROM fn_listextendedproperty (NULL, 'schema', 'dbo', 'table', 't1', 'column', 'col1');

SELECT    T.name AS Table_Name ,
          C.name AS Column_Name ,
          EP.value AS Column_Description
FROM      sys.tables AS T
JOIN      sys.columns C 
ON        T.object_id = C.object_id
LEFT JOIN sys.extended_properties EP 
ON        T.object_id = EP.major_id 
AND       C.column_id = EP.minor_id 
where t.name='ccRIAWorkGroupUsers'