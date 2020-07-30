create procedure ccspHunaku_getAcdDefaultById
				 @inbound_id integer
				 AS
					declare @nMaxQue smallint

					select @nMaxQue = nMaxQue from ccInbound where Inbound_id =@inbound_id

					if @nMaxQue is null 
					begin
						set @nMaxQue=0
						set @inbound_id=0
					end
					
					select @inbound_id  as inbound_id, 0 'is900', @nMaxQue as nMaxQue