# README #

Este documento al orden que se deben poner los objetos para la liberacion del release y validaciones necesarias para cuando se coloque algun script

## Orden de creacion de objetos ##

* DDL (Data Definition Language)
    * Create
    * Drop
    * Alter

* DML (Data Manipulation Language)
    * Select
    * Update
    * Delete
    * Insert

* Contraint Object Types
    * C = CHECK constraint
    * D = DEFAULT (constraint or stand-alone)
    * F = FOREIGN KEY constraint
    * PK = PRIMARY KEY constraint
    * R = Rule (old-style, stand-alone)
    * UQ = UNIQUE constraint

* Function Object Types
    * FN Scalar function
	* IF Inline table-valued function
	* TF Table-valued-function
	* FS Assembly (CLR) scalar-function
	* FT Assembly (CLR) table-valued function


### TABLES ###


```
-- When table exists
if exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

-- When table does not exists
if not exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end
#!sql




```