CREATE PROCEDURE [dbo].[ccsp_RIASearchLoading] 
@option smallint, 
@startDate datetime, 
@endDate datetime AS

if @option = 1
	begin
		select cam_id, load_id, camName, frame, [state], pctg, [description], case upPrepared when 0 then 'False' else 'True' end, 
		regsLoaded, telsLoaded, regsNotLoaded, telsNotLoaded, regsBlocked, telsBlocked, alreadyLoaded
		from ccRIALoading
		where convert(datetime,convert(varchar(11),loadDate)) >= @startDate
		and convert(datetime,convert(varchar(11),loadDate)) <= @endDate
		and [state] in (3,4)
	end