CREATE PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
			@user_id integer,
			@tel varchar(15)
			AS
			declare @mask integer, @idioma integer, @value integer, @lada integer
			declare @country as tinyint

			set @value = 0
			select @mask = isnull(dialmask,7) from ccusers where user_id=@user_id
			select @country = valor from ccsettings where setting_id = 104

			-- Restricciones por pais 1:Mexico 2:Argentina 3:Colombia 4:USA 5:Chile 6:Venezuela 7:uk 8:Arabia Saudita, 9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador
			if @country = 1
			 begin

				DECLARE @specialDialPlan TINYINT, @phoneType TINYINT
				SELECT @specialDialPlan = valor, @phoneType = 0
				FROM ccsettings WITH (NOLOCK)
				WHERE setting_id = 195

				if @specialDialPlan = 1 select @phoneType=dbo.fnGetCallType(@tel)

				--Restringe celulares
				if (@mask & 1)>0
				 begin
					if ((left(ltrim(rtrim(@tel)),3) = '044' Or left(ltrim(rtrim(@tel)),3) = '045') and len(ltrim(rtrim(@tel))) = 13) or (@specialDialPlan = 1 and (@phoneType=3 or @phoneType=4))
					 begin
						set @value = 4
					 end
				 end

				--Restringe larga distancia
				if(@value=0)
				 begin
					if ((@mask & 2) > 0)
					 begin
						if ((left(ltrim(rtrim(@tel)),2) = '01') and len(ltrim(rtrim(@tel))) = 12) or (@specialDialPlan = 1 and @phoneType=2)
						 begin
							set @value = 5
						 end
					 end
				 end

				--Restringe locales
				if(@value=0)
				 begin
					if ((@mask & 4) > 0)
					 begin
						select @lada=valor from ccSettings WHERE setting_id=17
						if (Len(@lada) + Len(ltrim(rtrim(@tel))) = 10 and @specialDialPlan = 0) or (@specialDialPlan = 1 and @phoneType=1)
						 begin
							set @value = 6
						 end
					 end
				 end
			 end

			-- Argentina
			if @country = 2
			 begin
				--Restringe celulares
				if ((@mask & 1) > 0)
				 begin
					if (left(@tel,2)='15') or (len(@tel)>=13 and substring(@tel,1,1)='0' and
						(substring(@tel,4,2)='15' or substring(@tel,5,2)='15' or substring(@tel,3,2)='15'))
					 begin
						set @value = 4
					 end
				 end

				--Restringe larga distancia
				if(@value=0)
				 begin
					if ((@mask & 2) > 0)
					 begin
						if ((left(ltrim(rtrim(@tel)),2) ='0') and len(ltrim(rtrim(@tel))) = 11)
						 begin
							set @value = 5
						 end
					 end
				 end

				--Restringe locales
				if(@value=0)
				 begin
					if ((@mask&4)>0)
					 begin
						select @lada=valor from ccSettings WHERE setting_id=17
						if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
						 begin
							set @value=6
						 end
					 end
				 end
			 end

			if @country = 3 --Colombia
			 begin
				--Restringe Celulares
				if ((@mask & 1) > 0)
				 begin
					if len(@tel) > 8
					 begin
						set @value = 4
					 end
				 end

				--Restringe larga distancia
				if(@value=0)
				 begin
					if ((@mask & 2) > 0)
					 begin
						if len(@tel) = 8 or left(@tel,1) = '0'
						 begin
							set @value = 5
						 end
					 end
				 end

				--Restringe locales
				if(@value=0)
				 begin
					if ((@mask & 4) > 0)
					 begin
						select @lada=valor from ccSettings WHERE setting_id=17
						if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
						 begin
							set @value = 6
						 end
					 end
				 end
			 end

			if @country = 4 --USA
			 begin
				--Restringe larga distancia usa
				if ((@mask & 2) > 0)
				 begin
					if len(ltrim(rtrim(@tel))) >= 11  and (left(ltrim(rtrim(@tel)),1) = '1')
					 begin
						set @value = 5
					 end
				 end

				--Restringe locales usa
				if(@value=0)
				 begin
					if ((@mask & 4) > 0)
					 begin
						select @lada=valor from ccSettings WHERE setting_id=17
						--if Len(ltrim(rtrim(@tel))) = 7
						if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
						 begin
							set @value = 6
						end
					 end
				 end
			 end

			--Chile
			if @country = 5
			 begin

					--Restringe Celulares
				if ((@mask & 1) > 0)
				 begin
					if len(@tel) >= 10 and left(@tel,2) = '09'
					 begin
						set @value = 4
					 end
				 end

					--Restringe Locales
				if(@value=0)
				 begin
					if ((@mask & 4) > 0)
					 begin
						if Len(@tel) in (6,7)
						 begin
							set @value = 6
						 end
					 end
				 end

				--Restringe larga distancia
				if(@value=0)
				 begin
					if ((@mask & 2) > 0)
					 begin
						if len(@tel) >= 8 and len(@tel) < 10
						 begin
							set @value = 5
						 end
					 end
				 end
			 end

			--Venezuela
			if @country = 6
			begin
					--Restringe Celulares
				if ((@mask & 1) > 0)
				 begin
					if len(@tel) >= 10 and left(@tel,2) = '04'
					 begin
						set @value = 4
					 end
				 end

				--Restringe larga distancia
				if(@value=0)
				 begin
					if ((@mask & 2) > 0)
					 begin
						if len(@tel) >= 10 and left(@tel,1) = '0'
						 begin
							set @value = 5
						 end
					 end
				 end

				--Restringe locales
				if(@value=0)
				 begin
					if ((@mask & 4) > 0)
					 begin
						select @lada=valor from ccSettings WHERE setting_id=17
						if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
						 begin
							set @value = 6
						 end
					 end
				 end

			end

			--United Kingdom
			if @country = 7
			begin
					--Restringe Celulares
				if ((@mask & 1) > 0)
				 begin
					if (len(@tel) >= 9) and left(@tel,2) = '07'
					 begin
						set @value = 4
					 end
				 end

				--Restringe larga distancia
				if(@value=0)
				 begin
					if ((@mask & 2) > 0)
					 begin
						if len(@tel) >= 9 and left(@tel,1) = '0'
						 begin
							set @value = 5
						 end
					 end
				 end

				--Restringe locales
				if(@value=0)
				 begin
					if ((@mask & 4) > 0)
					 begin
						if len(@tel) >= 9 and left(@tel,1) <> '0'
						 begin
							set @value = 6
						 end
					 end
				 end

			end

			--arabia saudita
			if @country = 8
			begin

				--Restringe celulares
				if (@mask & 1)>0
				 begin
					if (left(ltrim(rtrim(@tel)),2) = '05' and len(ltrim(rtrim(@tel))) = 10 )
					 begin
						set @value = 4
					 end
				 end

				--Restringe larga distancia
				if(@value=0)
				 begin
					if ((@mask & 2) > 0)
					 begin
						if ( left(ltrim(rtrim(@tel)),2) <> '05' and len(ltrim(rtrim(@tel))) in (11, 9))
						 begin
							set @value = 5
						 end
					 end
				 end

				--Restringe locales
				if(@value=0)
				 begin
					if ((@mask & 4) > 0)
					 begin
						select @lada=valor from ccSettings WHERE setting_id=17
						if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
						 begin
							set @value = 6
						 end
					 end
				 end
			end

			--Australia
			if @country = 9
			begin

				--Restringe celulares
				if (@mask & 1)>0
				 begin
					if (left(ltrim(rtrim(@tel)),2) = '04' and len(ltrim(rtrim(@tel))) = 10)
					 begin
						set @value = 4
					 end
				 end

				--Restringe larga distancia
				if(@value=0)
				 begin
					if ((@mask & 2) > 0)
					 begin
						if ( left(ltrim(rtrim(@tel)),2) <> '04' and len(ltrim(rtrim(@tel))) = 10)
						 begin
							set @value = 5
						 end
					 end
				 end

				--Restringe locales
				if(@value=0)
				 begin
					if ((@mask & 4) > 0)
					 begin
						select @lada=valor from ccSettings WHERE setting_id=17
						if ((Len(ltrim(rtrim(@tel))) = 8) or
							('0' + left(ltrim(rtrim(@tel)),1) = @lada and Len(ltrim(rtrim(@tel))) = 9) or
							(left(ltrim(rtrim(@tel)),2) = @lada and Len(ltrim(rtrim(@tel))) = 10))
						 begin
							set @value = 6
						 end
					 end
				 end
			end

			--Brasil
			if @country = 10
				begin
					declare @lon int
					--Restringe celulares
					if (@mask & 1)>0
					begin
						set @tel=ltrim(rtrim(@tel))
						set @lon=len(@tel)
						if
							(@lon in(7,8) and left(@tel,1) in ('6','7','8','9') )
							or (@lon=9 and left(@tel,1) = '9' )
							or (@lon=10 and substring(@tel,3,1) in ('6','7','8','9') )
							or (@lon=11 and substring(@tel,3,1) = '9')
							--or (@lon=12 and substring(@tel,5,1) in ('6','7','8','9') )
							--or (@lon=13 and substring(@tel,5,1) = '9' )
							--or (@lon=13 and substring(@tel,5,1) = '9' )
							begin
								set @value = 4
							end
					end

					--Restringe larga distancia
					if(@value=0)
					begin
						if ((@mask & 2) > 0)
						begin
							select @lada=valor from ccSettings WHERE setting_id=17
							set @tel=ltrim(rtrim(@tel))
							set @lon=len(@tel)
							if  @lon>=10 and left(@tel,2) <> @lada
							begin
								set @value = 5
							end
						end
					end
					--Restringe locales
					if(@value=0)
					begin
						if ((@mask & 4) > 0)
						begin
							select @lada=valor from ccSettings WHERE setting_id=17
							set @tel=ltrim(rtrim(@tel))
							set @lon=len(@tel)
							if @lon in (7,8,9) or (@lon in (10,11) and left(@tel,2)= @lada)
							begin
								set @value = 6
							end
						end
					end

					--Restringe por cobrar
					if(@value=0)
					begin
						declare @llamadasPorCobrar varchar(4);
						select @llamadasPorCobrar= valor from ccSettings where setting_id=126
						set @tel=ltrim(rtrim(@tel))
						set @lon=len(@tel)
						if @lon >= 12 and  left(@tel,2) = '90' and @llamadasPorCobrar='0'
						begin
							set @value = 10 -- pone para llamadas por cobrar
						end
					end

				end -- Termina Brasil


			--Guatemala
			if @country = 11
				begin
					--Restringe celulares
					if (@mask & 1)>0
					begin
						set @tel=ltrim(rtrim(@tel))
						if charindex(substring(@tel,1,1),'3,4,5') > 0
							set @value = 4
					end

					--Restringe locales
					if(@value=0)
					begin
						if ((@mask & 4) > 0)
						begin
							set @tel=ltrim(rtrim(@tel))
							if charindex(substring(@tel,1,1),'2,6,7') > 0
								set @value = 6
						end
					end

				end -- Termina Guatemala

			--Costa Rica
			if @country = 12
				begin
					--Restringe celulares
					if (@mask & 1)>0
					begin
						set @tel=ltrim(rtrim(@tel))
						if charindex(substring(@tel,1,1),'5,6,7,8') > 0
							set @value = 4
					end

					--Restringe locales
					if(@value=0)
					begin
						if ((@mask & 4) > 0)
						begin
							set @tel=ltrim(rtrim(@tel))
							if charindex(substring(@tel,1,1),'2,3,4') > 0
								set @value = 6
						end
					end

				end -- Termina Costa Rica

			--Salvador
			if @country = 13
				begin
					--Restringe celulares
					if (@mask & 1)>0
					begin
						set @tel=ltrim(rtrim(@tel))
						if charindex(substring(@tel,1,1),'6,7') > 0
							set @value = 4
					end

					--Restringe locales
					if(@value=0)
					begin
						if ((@mask & 4) > 0)
						begin
							set @tel=ltrim(rtrim(@tel))
							if charindex(substring(@tel,1,1),'2') > 0
								set @value = 6
						end
					end

				end -- Termina Salvador

			--Spain
			if @country = 14
				begin
					--Restringe celulares
					if (@mask & 1)>0
					begin
						set @tel=ltrim(rtrim(@tel))
						if charindex(substring(@tel,1,1),'6,7') > 0
							set @value = 4
					end

					--Restringe locales
					if(@value=0)
					begin
						if ((@mask & 4) > 0)
						begin
							set @tel=ltrim(rtrim(@tel))
							if charindex(substring(@tel,1,1),'8,9') > 0
								set @value = 6
						end
					end

				end -- Termina Spain

			select @value Response