CREATE PROCEDURE [ccspGenAgentReqTime]
@start_date	datetime
AS
BEGIN
	DECLARE @id int
	-- Only needs to calculate for systems with timetables
	-- => CREATE Timetables
END