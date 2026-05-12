-- Clean up existing procedures.
-- Not running without a backup of current version.
USE CCenterRIA

if exists (select * from sys.procedures where name = N'ccsp_GetCommonNotReadyStates')
begin
	DROP PROCEDURE ccsp_GetCommonNotReadyStates;
end

if exists (select * from sys.procedures where name = N'ccsp_RIACATNotReadyTypes')
begin
	DROP PROCEDURE ccsp_RIACATNotReadyTypes;
end