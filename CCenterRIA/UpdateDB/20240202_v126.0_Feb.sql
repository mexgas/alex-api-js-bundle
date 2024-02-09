/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K089000

Database: CCenterRia
Required version: 125.37

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 0
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;

--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY

        ----------------------------------------------------- BEGIN KR110000 ----------------------------------------------------------------

        SET @process = 'KR110001 TABLE CodesInterDialing'
        SET @sql = '
                    if not exists(select * from sys.tables where name=''CodesInterDialing'')
                    begin
                        create table CodesInterDialing(id int not null identity(1,1), Description varchar (50), ES varchar(max), EN varchar(max), PT varchar(max), Code varchar(25))

                        set identity_insert CodesInterDialing on

                        insert into CodesInterDialing(id, Description, ES, EN, PT)
                        values(1, ''america-code-1'', ''Estados Unidos de América (+1)'', ''United States of America (+1)'', ''Estados Unidos da América (+1)'')
                        ,(2, ''america-code-2'', ''Islas Vírgenes de EE. UU. (+1-340)'', ''Virgin Islands (U.S.) (+1-340)'', ''Ilhas Virgens Americanas (+1-340)'')
                        ,(3, ''america-code-3'', ''Islas Marianas del Norte (+1-670)'', ''Northern Mariana Islands (+1-670)'', ''Ilhas Marianas do Norte (+1-670)'')
                        ,(4, ''america-code-4'', ''Guam (+1-671)'', ''Guam (+1-671)'', ''Guam (+1-671)'')
                        ,(5, ''america-code-5'', ''Samoa Oriental (+1-684)'', ''American Samoa (+1-684)'', ''Samoa Americana  (+1-684)'')
                        ,(6, ''america-code-6'', ''Puerto Rico (+1)'', ''Puerto Rico (+1)'', ''Porto Rico (+1)'')
                        ,(7, ''america-code-7'', ''Canadá (+1)'', ''Canada (+1)'', ''Canadá (+1)'')
                        ,(8, ''america-code-8'', ''Bahamas (+1-242)'', ''Bahamas (+1-242)'', ''Bahamas (+1-242)'')
                        ,(9, ''america-code-9'', ''Barbados (+1-246)'', ''Barbados (+1-246)'', ''Barbados (+1-246)'')
                        ,(10, ''america-code-10'', ''Anguila (+1-264)'', ''Anguilla (+1-264)'', ''Anguila (+1-264)'')
                        ,(11, ''america-code-11'', ''Antigua y Barbuda (+1-268)'', ''Antigua and Barbuda (+1-268)'', ''Antígua e Barbuda (+1-268)'')
                        ,(12, ''america-code-12'', ''Islas Vírgenes Británicas (+1-284)'', ''Virgin Islands (British) (+1-284)'', ''Ilhas Virgens Britânicas (+1-284)'')
                        ,(13, ''america-code-13'', ''Islas Caimán (+1-345)'', ''Cayman Islands (+1-345)'', ''Ilhas Cayman (+1-345)'')
                        ,(14, ''america-code-14'', ''Bermudas (+1-441)'', ''Bermuda (+1-441)'', ''Bermudas (+1-441)'')
                        ,(15, ''america-code-15'', ''Granada (+1-473)'', ''Grenada (+1-473)'', ''Granada (+1-473)'')
                        ,(16, ''america-code-16'', ''Islas Turcas y Caicos (+1-649)'', ''Turks & Caicos (+1-649)'', ''Ilhas Turcos e Caicos (+1-649)'')
                        ,(17, ''america-code-17'', ''Jamaica (+1-876)'', ''Jamaica (+1-876)'', ''Jamaica (+1-876)'')
                        ,(18, ''america-code-18'', ''Montserrat (+1-664)'', ''Montserrat (+1-664)'', ''Montserrat (+1-664)'')
                        ,(19, ''america-code-19'', ''San Martín (zona neerlandesa) (+721)'', ''Sint Maarten (+721)'', ''São Martinho (parte holandesa) (+721)'')
                        ,(20, ''america-code-20'', ''Santa Lucía (+1-758)'', ''St. Lucia (+1-758)'', ''Santa Lúcia (+1-758)'')
                        ,(21, ''america-code-21'', ''Dominica (+1-767)'', ''Dominica (+1-767)'', ''Dominica (+1-767)'')
                        ,(22, ''america-code-22'', ''San Vicente y las Granadinas(+1-784)'', ''St. Vincent and the Grenadines (+1-784)'', ''São Vincente e Granadinas (+1-784)'')
                        ,(23, ''america-code-23'', ''República Dominicana (+1)'', ''Dominican Republic (+1)'', ''República Dominicana (+1)'')
                        ,(24, ''america-code-24'', ''Trinidad y Tobago (+1-868)'', ''Trinidad & Tobago (+1-868)'', ''Trinidad e Tobago (+1-868)'')
                        ,(25, ''america-code-25'', ''San Cristóbal y Nieves (+1-869)'', ''St. Kitts/Nevis (+1-869)'', ''São Cristóvão e Névis (+1-869)'')
                        ,(26, ''america-code-26'', ''Islas Malvinas (+500)'', ''Falkland Islands (+500)'', ''Ilhas Malvinas (+500)'')
                        ,(27, ''america-code-27'', ''Georgia del Sur e Islas Sandwich del Sur (+500)'', ''South Georgia and the South Sandwich Islands (+500)'', ''Ilhas Geórgia do Sul e Sandwich do Sul (+500)'')
                        ,(28, ''america-code-28'', ''Belice (+501)'', ''Belize (+501)'', ''Belize (+501)'')
                        ,(29, ''america-code-29'', ''Guatemala (+502)'', ''Guatemala (+502)'', ''Guatemala (+502)'')
                        ,(30, ''america-code-30'', ''El Salvador (+503)'', ''El Salvador (+503)'', ''El Salvador (+503)'')
                        ,(31, ''america-code-31'', ''Honduras (+504)'', ''Honduras (+504)'', ''Honduras (+504)'')
                        ,(32, ''america-code-32'', ''Nicaragua (+505)'', ''Nicaragua (+505)'', ''Nicarágua (+505)'')
                        ,(33, ''america-code-33'', ''Costa Rica (+506)'', ''Costa Rica (+506)'', ''Costa Rica (+506)'')
                        ,(34, ''america-code-34'', ''Panamá (+507)'', ''Panama (+507)'', ''Panamá (+507)'')
                        ,(35, ''america-code-35'', ''San Pedro y Miquelón (+508)'', ''St. Pierre and Miquelon (+508)'', ''São Pedro e Miquelon (+508)'')
                        ,(36, ''america-code-36'', ''Haití (+509)'', ''Haiti (+509)'', ''Haiti (+509)'')
                        ,(37, ''america-code-37'', ''Perú (+51)'', ''Peru (+51)'', ''Peru (+51)'')
                        ,(38, ''america-code-38'', ''México (+52)'', ''Mexico (+52)'', ''México (+52)'')
                        ,(39, ''america-code-39'', ''Cuba (+53)'', ''Cuba (+53)'', ''Cuba (+53)'')
                        ,(40, ''america-code-40'', ''Argentina (+54)'', ''Argentina (+54)'', ''Argentina (+54)'')
                        ,(41, ''america-code-41'', ''Brasil (+55)'', ''Brazil (+55)'', ''Brasil (+55)'')
                        ,(42, ''america-code-42'', ''Chile (+56)'', ''Chile (+56)'', ''Chile (+56)'')
                        ,(43, ''america-code-43'', ''Colombia (+57)'', ''Colombia (+57)'', ''Colômbia (+57)'')
                        ,(44, ''america-code-44'', ''Venezuela (+58)'', ''Venezuela (+58)'', ''Venezuela (+58)'')
                        ,(45, ''america-code-45'', ''Guadalupe (+590)'', ''Guadeloupe (+590)'', ''Guadalupe (+590)'')
                        ,(46, ''america-code-46'', ''Bolivia (+591)'', ''Bolivia (+591)'', ''Bolívia (+591)'')
                        ,(47, ''america-code-47'', ''Guyana (+592)'', ''Guyana (+592)'', ''Guiana (+592)'')
                        ,(48, ''america-code-48'', ''Ecuador (+593)'', ''Ecuador (+593)'', ''Equador (+593)'')
                        ,(49, ''america-code-49'', ''Guyana Francesa (+594)'', ''French Guiana (+594)'', ''Guiana Francesa (+594)'')
                        ,(50, ''america-code-50'', ''Paraguay (+595)'', ''Paraguay (+595)'', ''Paraguai (+595)'')
                        ,(51, ''america-code-51'', ''Martinica (+596)'', ''Martinique (+596)'', ''Martinica (+596)'')
                        ,(52, ''america-code-52'', ''Surinam (+597)'', ''Suriname (+597)'', ''Suriname (+597)'')
                        ,(53, ''america-code-53'', ''Uruguay (+598)'', ''Uruguay (+598)'', ''Uruguai (+598)'')
                        ,(54, ''america-code-54'', ''Antillas Neerlandesas (+599)'', ''Netherlands Antilles (+599)'', ''Antilhas Holandesas (+599)'')
                        ,(55, ''america-code-55'', ''Bonaire, San Eustaquio y Saba (+599)'', ''Bonaire, Sint Eustatius and Saba (+599)'', ''Bonaire, Santo Eustáquio e Saba(+599)'')
                        ,(56, ''america-code-56'', ''Curazao (+599)'', ''Curaçao (+599)'', ''Curaçao (+599)'')
                        ,(57, ''europa-code-1'', ''Grecia (+30)'', ''Greece (+30)'', ''Grécia (+30)'')
                        ,(58, ''europa-code-2'', ''Países Bajos (+31)'', ''Netherlands (+31)'', ''Países Baixos (+31)'')
                        ,(59, ''europa-code-3'', ''Bélgica (+32)'', ''Belgium (+32)'', ''Bélgica (+32)'')
                        ,(60, ''europa-code-4'', ''Francia (+33)'', ''France (+33)'', ''França (+33)'')
                        ,(61, ''europa-code-5'', ''España (+34)'', ''Spain (+34)'', ''Espanha (+34)'')
                        ,(62, ''europa-code-6'', ''Gibraltar (+350)'', ''Gibraltar (+350)'', ''Gibraltar (+350)'')
                        ,(63, ''europa-code-7'', ''Portugal (+351)'', ''Portugal (+351)'', ''Portugal (+351)'')
                        ,(64, ''europa-code-8'', ''Luxemburgo (+352)'', ''Luxembourg (+352)'', ''Luxemburgo (+352)'')
                        ,(65, ''europa-code-9'', ''Irlanda (+353)'', ''Ireland (+353)'', ''Irlanda (+353)'')
                        ,(66, ''europa-code-10'', ''Islandia (+354)'', ''Iceland (+354)'', ''Islândia (+354)'')
                        ,(67, ''europa-code-11'', ''Albania (+355)'', ''Albania (+355)'', ''Albânia (+355)'')
                        ,(68, ''europa-code-12'', ''Malta (+356)'', ''Malta (+356)'', ''Malta (+356)'')
                        ,(69, ''europa-code-13'', ''Chipre (+357)'', ''Cyprus (+357)'', ''Chipre (+357)'')
                        ,(70, ''europa-code-14'', ''Finlandia (+358)'', ''Finland (+358)'', ''Finlândia (+358)'')
                        ,(71, ''europa-code-15'', ''Bulgaria (+359)'', ''Bulgaria (+359)'', ''Bulgária (+359)'')
                        ,(72, ''europa-code-16'', ''Hungría (+36)'', ''Hungary (+36)'', ''Hungria (+36)'')
                        ,(73, ''europa-code-17'', ''Lituania (+370)'', ''Lithuania (+370)'', ''Lituânia (+370)'')
                        ,(74, ''europa-code-18'', ''Letonia (+371)'', ''Latvia (+371)'', ''Letônia (+371)'')
                        ,(75, ''europa-code-19'', ''Estonia (+372)'', ''Estonia (+372)'', ''Estônia (+372)'')
                        ,(76, ''europa-code-20'', ''Moldavia (+373)'', ''Moldova (+373)'', ''Moldova (+373)'')
                        ,(77, ''europa-code-21'', ''Armenia (+374)'', ''Armenia (+374)'', ''Armênia (+374)'')
                        ,(78, ''europa-code-22'', ''Bielorrusia (+375)'', ''Belarus (+375)'', ''Bielo-Rússia (+375)'')
                        ,(79, ''europa-code-23'', ''Andorra (+376)'', ''Andorra (+376)'', ''Andorra (+376)'')
                        ,(80, ''europa-code-24'', ''Mónaco (+377)'', ''Monaco (+377)'', ''Mônaco (+377)'')
                        ,(81, ''europa-code-25'', ''San Marino (+378)'', ''San Marino (+378)'', ''São Marinho (+378)'')
                        ,(82, ''europa-code-26'', ''Ciudad del Vaticano (+379)'', ''Vatican City (+379)'', ''Cidade do Vaticano (+379)'')
                        ,(83, ''europa-code-27'', ''Ucrania (+380)'', ''Ukraine (+380)'', ''Ucrânia (+380)'')
                        ,(84, ''europa-code-28'', ''Serbia (+381)'', ''Serbia (+381)'', ''Sérvia (+381)'')
                        ,(85, ''europa-code-29'', ''Montenegro (+382)'', ''Montenegro (+382)'', ''Montenegro (+382)'')
                        ,(86, ''europa-code-30'', ''Kosovo (+383)'', ''Kosovo (+383)'', ''Kosovo (+383)'')
                        ,(87, ''europa-code-31'', ''Croacia (+385)'', ''Croatia (+385)'', ''Croácia (+385)'')
                        ,(88, ''europa-code-32'', ''Eslovenia (+386)'', ''Slovenia (+386)'', ''Eslovênia (+386)'')
                        ,(89, ''europa-code-33'', ''Bosnia y Herzegovina (+387)'', ''Bosnia/Herzegovina (+387)'', ''Bósnia e Herzegovina (+387)'')
                        ,(90, ''europa-code-34'', ''Macedonia (+389)'', ''Macedonia (+389)'', ''Macedônia (+389)'')
                        ,(91, ''europa-code-35'', ''Italia (+39)'', ''Italy (+39)'', ''Itália (+39)'')
                        ,(92, ''europa-code-36'', ''Rumania (+40)'', ''Romania (+40)'', ''Romênia (+40)'')
                        ,(93, ''europa-code-37'', ''Suiza (+41)'', ''Switzerland (+41)'', ''Suíça (+41)'')
                        ,(94, ''europa-code-38'', ''República Checa (+420)'', ''Czech Republic (+420)'', ''República Tcheca (+420)'')
                        ,(95, ''europa-code-39'', ''República Eslovaca (+421)'', ''Slovak Republic (+421)'', ''República Eslovaca (+421)'')
                        ,(96, ''europa-code-40'', ''Liechtenstein (+423)'', ''Liechtenstein (+423)'', ''Liechtenstein (+423)'')
                        ,(97, ''europa-code-41'', ''Austria (+43)'', ''Austria (+43)'', ''Áustria (+43)'')
                        ,(98, ''europa-code-42'', ''Reino Unido (+44)'', ''United Kingdom (+44)'', ''Reino Unido (+44)'')
                        ,(99, ''europa-code-43'', ''Guernesey (+44-1481)'', ''Guernsey (+44-1481)'', ''Guernsey (+44-1481)'')
                        ,(100, ''europa-code-44'', ''Bailía de Jersey (+44-1534)'', ''Jersey (+44-1534)'', ''Protetorado de Jersey (+44-1534)'')
                        ,(101, ''europa-code-45'', ''Isla de Man (+44-1624)'', ''Isle of Man (+44-1624)'', ''Ilha de Man (+44-1624)'')
                        ,(102, ''europa-code-46'', ''Dinamarca (+45)'', ''Denmark (+45)'', ''Dinamarca (+45)'')
                        ,(103, ''europa-code-47'', ''Suecia (+46)'', ''Sweden (+46)'', ''Suécia (+46)'')
                        ,(104, ''europa-code-48'', ''Noruega (+47)'', ''Norway (+47)'', ''Noruega (+47)'')
                        ,(105, ''europa-code-49'', ''Islas Svalbard y Jan Mayen(+47)'', ''Svalbard and Jan Mayen (+47)'', ''Ilhas de Svalbard e Jan Mayen(+47)'')
                        ,(106, ''europa-code-50'', ''Polonia (+48)'', ''Poland (+48)'', ''Polônia (+48)'')
                        ,(107, ''europa-code-51'', ''Alemania (+49)'', ''Germany (+49)'', ''Alemanha (+49)'')

                        set identity_insert CodesInterDialing off

                        update CodesInterDialing
                        set Code = SUBSTRING(ES, CHARINDEX(''+'', ES) + 1, CHARINDEX(''+'', REVERSE(ES)) - 2)


                        alter table ccoDialers add DialingType bit not null default 1, IdCode int not null default 0                        
                    end'
        EXEC(@sql);

        SET @process = 'KR110001 DROP SP GetInterDialing'
        SET @sql = '
                    if exists(select * from sys.procedures where name = ''GetInterDialing'')
                    begin
                        DROP PROCEDURE GetInterDialing
                    end'
        EXEC(@sql);        

        SET @process = 'KR110001 CREATE SP GetInterDialing'
        SET @sql = '
                    CREATE PROCEDURE [dbo].[GetInterDialing]

                    AS
                    BEGIN

                    declare @language tinyint
                    select @language = valor from ccSettings nolock where setting_id = 27

                    select 
                    id
                    , case
                        when @language = 0 then ES
                        when @language = 1 then EN
                        else PT end description
                    , Code 
                    from CodesInterDialing nolock

                    END'
        EXEC(@sql);

        SET @process = 'KR110001 ADD COLUMN DialingType '
        SET @sql = 'if not exists (select * from sys.columns where name = N''DialingType'' and Object_ID = Object_ID(N''ccoDialers''))
                    begin
                        alter table ccoDialers add DialingType bit not null default 1, IdCode int not null default 0
                    end'
        EXEC(@sql);

        SET @process = 'KR110001 ADD ccGalateaModules'
        SET @sql = '
                    IF NOT EXISTS(SELECT 1 FROM ccGalateaModules WHERE ModuleId = 14)
                    BEGIN
                        insert into ccGalateaModules(ModuleId, MTagEs, MTagEn, MTagPt)
                        values(14, ''Puertos de marcación'', ''Dialing ports'', ''Portas de discagem'')
                    END'
        EXEC(@sql);      

        SET @process = 'KR110001 ADD ccGalateaOperations'
        SET @sql = '
                    IF NOT EXISTS(SELECT 1 FROM ccGalateaOperations WHERE OperationId = 95)
                    BEGIN
                        insert into ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
                        values(95, ''Editar puerto'', ''Edit port'', ''Editar porta'')
                    END'
        EXEC(@sql);       

        SET @process = 'KR110001 ALTER PROCEDURE ccsp_GalateaDialer'
        SET @sql = '
                    ALTER PROCEDURE [dbo].[ccsp_GalateaDialer]
                    @Description varchar(40)='''',
                    @DialerId int = 0,
                    @PortNumber int = 0,
                    @Status varchar(1)='''',
                    @action smallint=0,
                    @Provider smallint=0,
                    @XferType smallint=0,
                    @PortEnd int = 0,
                    @CampId smallint = 0,
                    @dialer_ids varchar(2000)='''',
                    @DialingType tinyint = 0,--1,
                    @idDialingCode int = 0--38

                    AS
                    set nocount on

                    if @action=1
                    begin
                        select provedor_id as ProviderId, descrip as ProviderName  from cstoProvedor
                    end

                    if @action=2 --Insert
                    begin
                        create table #tempPortTable( portId int primary key)

                        if @PortEnd>0 begin
                            begin transaction
                                while @PortNumber<=@portEnd begin
                                insert into #tempPortTable values(@PortNumber)
                                set @PortNumber=@PortNumber+1
                                end
                            commit transaction
                        end
                        else begin
                            insert into #tempPortTable values(@PortNumber)
                        end
                        
                        if exists(select Puerto from ccoDialers where Puerto in (select portId from #tempPortTable))
                        begin
                            drop table #tempPortTable
                            select -1 as ResponseCode
                            return(0)
                        end

                        Insert ccoDialers (Descripcion, Puerto, Status, provedor_id, xfertype, DialingType, IdCode) 
                        Select @Description+''_''+CAST(portId as varchar(5)), portId, @Status, @Provider, @XferType, case @DialingType when 2 then 0 else @DialingType end, @idDialingCode from #tempPortTable t
                        

                        select 200 as ResponseCode, dialer_id as DialerId, Descripcion as PortDescription, 
                        p.descrip as ProviderDescription, Puerto, XferType, DialingType
                        from ccoDialers d
                        inner join cstoProvedor p on p.provedor_id=d.provedor_id
                        where Puerto in (select portId from #tempPortTable)

                        drop table #tempPortTable
                    end

                    if @action=3 --Update
                    begin

                        if exists(select Puerto from ccoDialers where Puerto=@PortNumber and dialer_id <> @DialerId)
                        begin
                            select -1 as ResponseCode ---Port already exists
                            return(0)
                        end

                        Update ccoDialers set Descripcion=case @Description when '''' then Descripcion else @Description+''_''+cast(@PortNumber as varchar(5)) end,
                        Puerto=case @PortNumber when '''' then Puerto else @PortNumber end, Status=case @Status when '''' then Status else @status end,
                        provedor_id=case @Provider when '''' then provedor_id else @Provider end,
                        xfertype = case @XferType when 0 then xfertype else @XferType end,
                        DialingType = case when @DialingType = 0 then DialingType when @DialingType = 2 then 0 else @DialingType end,
                        IdCode = case @idDialingCode when 0 then IdCode else @idDialingCode end
                        where Dialer_id=cast(@DialerId as int)
                        
                        select 200 as ResponseCode, dialer_id as DialerId, Descripcion as PortDescription, 
                        p.descrip as ProviderDescription, Puerto, XferType, DialingType, case when DialingType = 1 then 0 else IdCode end as DialingCode
                        from ccoDialers d
                        inner join cstoProvedor p on p.provedor_id=d.provedor_id
                        where dialer_id=@DialerId
                    end

                    if @action=4 --Delete
                    begin

                        if exists(select Dialer_id from ccoDialerCamp where
                            Dialer_id in (select Value from dbo.fn_RIASplitDelimited (@dialer_ids, '','')))
                        begin
                            select -2 as ResponseCode --Existe alguna campaña que esta utilizando este dialer
                            return(0)
                        end
                        
                        declare @portsDelete table(DialerId int, Port int,PortDescription varchar(15))

                        insert @portsDelete (DialerId,Port,PortDescription)
                        select Value, Puerto,Descripcion from dbo.fn_RIASplitDelimited (@dialer_ids, '','') 
                        inner join ccoDialers on dialer_id=Value

                        delete from ccoDialers Where Dialer_id in (select DialerId from @portsDelete)
                        
                        select 200 as ResponseCode, DialerId, PortDescription
                        from @portsDelete
                    end

                    if @action=5 --Ports Info
                    begin
                        select dc.cam_id as CampId, c.cam_descripcion as CampName, graphic_id as Frame, c.IDArea, a.AreaName
                        from ccoDialerCamp dc
                        inner join ccCamps c on c.cam_id=dc.cam_id
                        inner join ccRIACat_Areas a on a.IDArea=c.IDArea
                        inner join ccRIACampsGraph cg on c.cam_id=cg.cam_id
                        where dc.dialer_id=@DialerId

                        return(0)
                    end

                    set nocount off'
        EXEC(@sql);   

        SET @process = 'KR110001 ALTER PROCEDURE ccsp_GalateaAdminPortsManagement'
        SET @sql = '
                    ALTER PROCEDURE [dbo].[ccsp_GalateaAdminPortsManagement]
                    @action SMALLINT,
                    @dialer_id INT = 0,
                    @cam_id SMALLINT = 0,
                    @list_dialier_id varchar(max) =''''
                    AS
                    SET NOCOUNT ON;
                    DECLARE @transtate BIT
                    IF @@TRANCOUNT = 0
                    BEGIN
                        SET @transtate = 1
                    BEGIN TRANSACTION transtate
                    END
                    BEGIN TRY
                        IF @action = 1 --return all ports
                        BEGIN
                            SELECT Dialers.dialer_id AS DialerId, Dialers.Descripcion AS PortDescription, Provedor.Descrip AS ProviderDescription, Dialers.Puerto, XferType, DialingType, case when DialingType = 1 then 0 else IdCode end AS DialingCode
                            FROM [CCenterRIA].[dbo].[ccoDialers] AS Dialers INNER JOIN [CCenterRIA].[dbo].[cstoProvedor] AS Provedor 
                            ON Dialers.provedor_id = Provedor.provedor_id
                        END;
                        IF @action = 2 --return ports for camp
                        BEGIN
                            SELECT dialer_id AS DialerId, cam_id AS CampId FROM [CCenterRIA].[dbo].[ccoDialerCamp] ORDER BY cam_id
                        END;
                        IF @action = 3 --insert port
                        BEGIN
                            IF @list_dialier_id = ''''
                            BEGIN
                                IF NOT EXISTS (SELECT dialer_id, cam_id FROM [CCenterRIA].[dbo].[ccoDialerCamp]
                                    WHERE dialer_id=@dialer_id AND cam_id=@cam_id)
                                BEGIN
                                    INSERT INTO [CCenterRIA].[dbo].[ccoDialerCamp](dialer_id, cam_id) VALUES (@dialer_id, @cam_id)
                                END;
                            END
                            ELSE
                            BEGIN
                            INSERT INTO [CCenterRIA].[dbo].[ccoDialerCamp](dialer_id, cam_id)
                                Select dialer_id,@cam_id from ccoDialers where dialer_id not in (SELECT dialer_id FROM [CCenterRIA].[dbo].[ccoDialerCamp]
                                    WHERE dialer_id in (select Value FROM fn_RIASplitDelimited(@list_dialier_id, '','') where [value] > 0) AND cam_id=@cam_id) and
                                    dialer_id in (select Value FROM fn_RIASplitDelimited(@list_dialier_id, '',''))
                            END;
                        END;
                        IF @action = 4 --delete port
                        BEGIN
                            IF @list_dialier_id = ''''
                                DELETE FROM [CCenterRIA].[dbo].[ccoDialerCamp] WITH(ROWLOCK) WHERE cam_id = @cam_id AND dialer_id = @dialer_id
                            ELSE
                            BEGIN
                                DELETE FROM [CCenterRIA].[dbo].[ccoDialerCamp] WITH(ROWLOCK) WHERE cam_id = @cam_id AND dialer_id in (select Value FROM fn_RIASplitDelimited(@list_dialier_id, '','') where [value] > 0)
                            END;
                        END;

                        IF @action = 5 --return ports for single camp
                        BEGIN
                            SELECT dialer_id AS DialerId, cam_id AS CampId FROM [CCenterRIA].[dbo].[ccoDialerCamp] WHERE cam_id = @cam_id ORDER BY cam_id
                        END;

                        IF @transtate = 1 AND XACT_STATE() = 1
                        BEGIN
                            COMMIT TRANSACTION transtate
                        END;
                    END TRY
                    BEGIN CATCH
                    DECLARE @error INT, @message VARCHAR(4000), @xstate INT;
                    SELECT @error = ERROR_NUMBER(), @message = ERROR_MESSAGE(), @xstate = XACT_STATE();
                    IF @xstate = -1
                        ROLLBACK;
                    IF @xstate = 1
                        ROLLBACK
                    IF @xstate = 1
                        ROLLBACK TRANSACTION ccsp_GalateaAdminPortsManagement;
                    RAISERROR (''ccsp_GalateaAdminPortsManagement: %d: %s'', 16, 1, @error, @message) ;
                    END CATCH;'
        EXEC(@sql);                       

        SET @process = 'KR110001 ALTER PROCEDURE ccsp_OUTGetNewJobs'
        SET @sql = '
					ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
							@CAMPID int,
							@test int=0,
							@nAgentsLogin int=1,
							@iZonas int = NULL,
							@isDashboardApi BIT = 0
							as
							--set nocount on
							declare @total int
							declare @topCount smallint, @bIsDaylight bit, @revHorario bit
							declare @country_id int, @TipoJobs int
							--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
							declare @sql varchar(MAX), @Order_Asc_Desc char(4)
							declare @camSurvey INT, @campType INT;
							select @camSurvey = 0
							DECLARE @iZonasTable TABLE (value int)
							declare @maxRecs varchar(3) = 0

							select @maxRecs = valor from ccsettings (nolock) where setting_id = 251 and Status = 1		
							select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0;
							SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id =  @CAMPID;

							-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
							SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
							select @revHorario=valor from ccsettings where setting_id = 112
							-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
							SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
							SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

							SET DATEFIRST 1
							--Checamos si es horario de verano
							select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

							if @iZonas is null begin

								INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
								select @iZonas=value from @iZonasTable
							--Checamos si la campaña tiene horarios configurados
								if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
								begin
											if @iZonas = 0 begin
													SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
													return
											end
								end
								else begin
										if @camSurvey > 0
											begin
													SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
													return
											end
								end
							end

							set @sql=''CREATE TABLE #NEW_JOBS
							(callout_id int,
								cam_id int,
								cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
								cal_status tinyint,
								cal_fechaDial datetime,
								user_id int,
								tz int,
							tz2 int,
							tz3 int,
							tz4 int,
							tz5 int,
							list_id int,
							sequence smallint,
							calkey varchar(max),
							nDescartes int,
							name_agent varchar(max),
							SimultaneousRecs int,
							international bit
							)''


							-- 0=Ambas, 1=CallBacks, 2=Nuevas
							select @topCount=valor from ccSettings where setting_id=94

							if isnull(@topCount,0)=0
							select @topCount=case when @nAgentsLogin<3 then 30
								when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
								when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
								when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
								when @nAgentsLogin>=16 then 240 else 20 end

							select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

							declare @isVerano varchar(max)
							set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' END
							
							IF(@campType = 7)
							BEGIN
								set @isVerano = ''W.iTimeZone'' + case @bIsDaylight when 1 then ''_summer'' else '''' END
							END


							if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
							begin

										select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

										select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';

										IF(@campType = 7)
										BEGIN
											select @sql=@sql+nchar(13)+ ''SELECT W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial, W.user_id,''
											+@isVerano+'',''
											+@isVerano+''2,''
											+@isVerano+''3,''
											+@isVerano+''4,''
											+@isVerano+''5,
											W.list_id, isNull(R.sequence,0) as sequence,
											sos.callkey+''''~''''+rtrim(data1)+''''~''''+rtrim(data2)+''''~''''+rtrim(data3)+''''~''''+rtrim(data4)+''''~''''+rtrim(data5) calkey, 0 AS nDescartes,
											isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, 0 SimultaneousRecs, 0 international
											FROM smsWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
											left join smsOutSource sos (nolock) on sos.smsout_id=W.smsout_id
											left join ccUsers us (nolock) on us.User_id=w.user_id
											WHERE W.sms_status=1 -- CallBacks
											and W.sms_dateDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
											and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
											and (
												( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''=0) or
												((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2=0) or
												((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3=0) or
												((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4=0) or
												((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5=0)
											)
											and isnull(R.status,2) = 2
											order by priority_cb desc, W.sms_dateDial ''  + @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
										END
										ELSE
										BEGIN
											select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
											+@isVerano+'',''
											+@isVerano+''2,''
											+@isVerano+''3,''
											+@isVerano+''4,''
											+@isVerano+''5,
											W.list_id, isNull(R.sequence,0) as sequence,
											cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
											isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs, isnull(cs.international, 0) international
											FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
											left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
											left join ccUsers us (nolock) on us.User_id=w.user_id
											left join ccCampsExtend ce on ce.cam_id=W.cam_id
											WHERE W.cal_status=1 -- CallBacks
											and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
											and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
											and (
												( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
												((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
												((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
												((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
												((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
											)
											and isnull(R.status,2) = 2
											order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
										END
										
							end -- TOMA EN CUENTA LOS CALLBACKS

							if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
							begin
										select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar );

										select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';

										IF(@campType = 7)
										BEGIN
											select @sql=@sql+nchar(13)+ ''SELECT W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial, W.user_id,''
											+@isVerano+'',''
											+@isVerano+''2,''
											+@isVerano+''3,''
											+@isVerano+''4,''
											+@isVerano+''5,
											W.list_id, isNull(R.sequence,0) as sequence,
											sos.callkey+''''~''''+rtrim(data1)+''''~''''+rtrim(data2)+''''~''''+rtrim(data3)+''''~''''+rtrim(data4)+''''~''''+rtrim(data5) calkey, 0 AS nDescartes,
											isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, 0 SimultaneousRecs, 0 international
											FROM smsWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
											left join smsOutSource sos (nolock) on sos.smsout_id=W.smsout_id
											left join ccUsers us (nolock) on us.User_id=w.user_id
											WHERE W.sms_status=0 -- Nuevas
											and W.sms_dateDial < dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
											and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
											and (
												( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''=0) or
												( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2=0) or
												( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3=0) or
												( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4=0) or
												( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5=0)
											)
											and isnull(R.status,2) = 2
											order by R.sequence, W.sms_dateDial ''+ @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc
										END
										ELSE
										BEGIN
											select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
											+@isVerano+'',''
											+@isVerano+''2,''
											+@isVerano+''3,''
											+@isVerano+''4,''
											+@isVerano+''5,
											W.list_id, isNull(R.sequence,0) as sequence,
											cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
											isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs, isnull(cs.international, 0) international
											FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
											left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
											left join ccUsers us (nolock) on us.User_id=w.user_id
											left join ccCampsExtend ce on ce.cam_id=W.cam_id
											WHERE W.cal_status=0 -- Nuevas
											and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
											and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
											and (
												( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
												( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
												( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
												( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
												( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
											or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
											)
											and isnull(R.status,2) = 2
											order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc
										END

							end -- TOMA EN CUENTA LAS NUEVAS
							----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
							select @sql=@sql+nchar(13)+ ''SET rowcount 0''
							if @Test=0
								begin
										select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
										WHERE callout_id in(select callout_id from #NEW_JOBS)''
							end

							if @Test = 2
							begin
								select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
								declare @nSQL nvarchar(4000)
								set @nSQL=cast(@sql as nvarchar(4000))
								exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
								return(@total)
							end
							else
							BEGIN
								IF(@isDashboardApi = 1)
								BEGIN
										select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

										select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
										SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
										+@isVerano+'',''
										+@isVerano+''2,''
										+@isVerano+''3,''
										+@isVerano+''4,''
										+@isVerano+''5,
										W.list_id, isNull(R.sequence,0) as sequence,
										cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
										isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs, isnull(cs.international, 0) international
										FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
										left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
										left join ccUsers us (nolock) on us.User_id=w.user_id
										left join ccCampsExtend ce on ce.cam_id=W.cam_id
										WHERE W.cal_status= 2 -- Procesando
										and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
										and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
										and (
											( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
										or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
											( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
										or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
											( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
										or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
											( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
										or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
											( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
										or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
										)
										and isnull(R.status,2) = 2
										order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc
										-- TOMA EN CUENTA LOS REGISTROS PROCESANDOSE
								END

								select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
								user_id, tz, tz2, tz3, tz4, tz5,
								case when tz is null then '''''''' else cal_telefono end as tel,
								case when tz2 is null then '''''''' else cal_telefono end as tel2,
								case when tz3 is null then '''''''' else cal_telefono end as tel3,
								case when tz4 is null then '''''''' else cal_telefono end as tel4,
								case when tz5 is null then '''''''' else cal_telefono end as tel5,
								NULL as dialOrder, list_id, sequence, calkey,
								0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type, nDescartes, name_agent, SimultaneousRecs,'' + @maxRecs + '' maxRecs, international
								FROM #NEW_JOBS where len(cal_telefono)>0

								---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
								declare @regval int
								SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
								exec ccsp_GetCampsNvosCB @cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + '',@Tipo=0,@user_id =0
								''
							end

							set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
							--print (@sql)
							exec(@sql)

							return(0)'
        EXEC(@sql);

        SET @process = 'KR110001 ALTER PROCEDURE ccspOutDialerCsto'
        SET @sql = '
					ALTER proc [dbo].[ccspOutDialerCsto]
					as
					set nocount on
					declare @modePlian int 
					declare @sql as varchar(max), @insert as varchar(max), @sql2 as varchar(max), @query as varchar(max), @country tinyint
					set @modePlian=0
					declare @RtnValue table (prov_Id int identity(1,1), costoloc decimal(15,3), costoLD decimal(15,3), costoCel decimal(15,3), costoCelLD decimal(15,3), costo01800 decimal(15,3), costoLDUsa decimal(15,3), costoLDInter decimal(15,3))
					select @country = valor from ccsettings where setting_id = 104
					set @query = ''declare @RtnValue table (provedor_id int ''
					set @sql = ''select provedor_id ''
					set @insert = ''''
					if @country>1 begin
					select @sql = @sql + '', sum(case when tipollamada_id = '' + convert(varchar(3),tipollamada_id) + '' then isnull(minutoUno,100) else 0 end) [''+ descrip +'']'', @insert = @insert + '', [''+ descrip +'']'', @query = @query + '', ['' + descrip +''] decimal(15,3) '' 
					from cstotipollamada where country_id = @country
					end
					else begin
					select @sql = @sql + '', sum(case when tipollamada_id = '' + convert(varchar(3),tipollamada_id) + '' then isnull(minutoUno,100) else 0 end) [''+ descrip +'']'', @insert = @insert + '', [''+ descrip +'']'', @query = @query + '', ['' + descrip +''] decimal(15,3) '' 
					from cstotipollamada 
					where country_id=@country and ( tipoLlamada_id not in(1,12)  or  (@modePlian=0 and tipoLlamada_id=1) or (@modePlian<>0 and tipoLlamada_id=12) ) 

					end
					set @sql = '' Insert Into @RtnValue (provedor_id'' + @insert + '') '' + @sql + '' from cstotarifa group by provedor_id ''
					set @query = @query + '')''
					set @sql2 = '' select dialer_id, Puerto, Extension, Status, Descripcion, d.provedor_id, DialingType, isnull(Code, 0) Code'' + @insert + '' FROM ccoDialers d (nolock) Left Join @RtnValue c on d.provedor_id = c.provedor_id Left Join CodesInterDialing cd (nolock) on d.IdCode = cd.id ORDER BY Puerto''
					print (@query + @sql + @sql2)
					exec (@query + @sql + @sql2)'
        EXEC(@sql);				
      
        ----------------------------------------------------- END KR110000----------------------------------------------------------------
        ----------------------------------------------------- BEGIN Fri ----------------------------------------------------------------
		SET @process = 'KR110000 ADD COLUMN recordsNotLoadedPort'
        SET @sql = '
		if not exists (select * from sys.columns where name = N''recordsNotLoadedPort'' and Object_ID = Object_ID(N''ccRIALoading''))
		begin
			alter table ccRIALoading add recordsNotLoadedPort int null
		end'
        EXEC(@sql);

		SET @process = 'KR110000 ADD COLUMN phonesNotLoadedPort '
        SET @sql = '
		if not exists (select * from sys.columns where name = N''phonesNotLoadedPort'' and Object_ID = Object_ID(N''ccRIALoading''))
		begin
			alter table ccRIALoading add phonesNotLoadedPort int null
		end'
        EXEC(@sql);

		SET @process = 'KR110000 ADD COLUMN INTERNATIONAL'
        SET @sql = '
		if not exists (select * from sys.columns where name = N''international'' and Object_ID = Object_ID(N''ccoCallsOutSource''))
		begin
			alter table ccoCallsOutSource add international bit null
		end'
        EXEC(@sql);

		SET @process = 'KR110000 ALTER COLUMN MOTIVO'
        SET @sql = '
		if exists (select * from sys.columns where name = N''motivo'' and Object_ID = Object_ID(N''ccRIALogPhones''))
		begin
			alter table ccRIALogPhones alter column motivo varchar(100)
		end'
        EXEC(@sql);

        SET @process = 'KR110000 DROP SP ccsp_GalateaGetOutboundConfiguration'
        SET @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_GalateaGetOutboundConfiguration'')
		begin
			DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration;
		end'
        EXEC(@sql);

		SET @process = 'KR110000 CREATE SP ccsp_GalateaGetOutboundConfiguration'
        SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT
		,@campID INT
		AS
		BEGIN
		DECLARE @AllCampaigns TABLE (
		cam_id SMALLINT
		,cam_Descripcion VARCHAR(60)
		,cam_tNotas SMALLINT
		,cam_ocupado SMALLINT
		,cam_noInt_ocupado SMALLINT
		,cam_inter_ocupado SMALLINT
		,cam_nocontesto SMALLINT
		,cam_noInt_nocontesto SMALLINT
		,cam_inter_nocontesto SMALLINT
		,cam_fax SMALLINT
		,cam_noInt_fax SMALLINT
		,cam_inter_fax SMALLINT
		,cam_modomanual SMALLINT
		,ANI VARCHAR(15)
		,cam_ShowCalifWnd BIT
		,cam_StartTimerOnHangUp BIT
		,editableCallKey BIT
		,cam_tNoContesta SMALLINT
		,iTipoDial SMALLINT
		,detectAnswerMachine SMALLINT
		,detectVoiceMail SMALLINT
		,compliance SMALLINT
		,cam_inter_graba SMALLINT
		,cam_noint_graba SMALLINT
		,progDial SMALLINT
		,excCallBack SMALLINT
		,dialOrder SMALLINT
		,dialPrefix VARCHAR(10)
		,dialPrefixMan VARCHAR(10)
		,dialPrefixXfe VARCHAR(10)
		,listenManualCall BIT
		,stopRecording BIT
		,abandonCallback BIT
		,frame SMALLINT
		,t_autoCB SMALLINT
		,id_anilist INT
		,tDialonWrapUp SMALLINT
		,viewMode TINYINT
		,queSize SMALLINT
		,DNCScrub INT
		,callerIdDesc VARCHAR(15)
		,timeZoneRule INT
		,callsBySurvey INT
		,ivrScript INT
		,surveyPctg INT
		,call_record SMALLINT
		,startStopRecording BIT
		,leaveRecMessage BIT
		,manualCallOnChat BIT
		,callBackSurveyAgent BIT
		,callBackSurveyClient BIT
		,isRelationSurvey BIT
		,funcEspDtmf INT
		,sipHdrFormat VARCHAR(255)
		,cam_inter_cancelled SMALLINT
		,prefijo VARCHAR(40)
		,enbleprefix BIT
		,exitAssisted BIT
		,previewDiscard BIT
		,CampType INT
		,conexionInfo VARCHAR(50)
		,connUser VARCHAR(15)
		,closeConversationTime INT
		,answerTimeoutClient INT
		,allowFileAttachments BIT
		,selectRotativeANI INT
		,rotativeAlgo TINYINT
		,autoStart BIT
		,messagingOrder BIT
		,CamTPreview SMALLINT
		,TimesPreview TINYINT
		,timesDiscard TINYINT
		,recordHold BIT
		,zipCodeSchedule BIT
		,RecordCalls tinyint
		,simultaneousRecs smallint
		,EditableContactData bit
		,internationalDialingPortsAssigned bit
		)
		DECLARE @numbers VARCHAR(max)

		SELECT @numbers = COALESCE(@numbers + '''', '''', '''''''') + number
		FROM ccWhatsAppNumbers
		WHERE camp_id = 0
		AND STATUS = 1

		INSERT INTO @AllCampaigns
		EXEC ccsp_RIAConfCamp @adminID
		,@campID

		SELECT dialPrefixMan DialPrefixMan
		,dialPrefixXfe DialPrefixXfe
		,listenManualCall ListenManualCall
		,stopRecording StopRecording
		,abandonCallback AbandonCallBack
		,t_autoCB AutoCB
		,id_anilist IdIstANI
		,tDialonWrapUp TDialOnWrapup
		,queSize Quesize
		,DNCScrub
		,callerIdDesc CallerIdDesc
		,timeZoneRule TimeZoneRule
		,callsBySurvey CallsBySurvey
		,ivrScript IvrScript
		,surveyPctg SurveyPctg
		,call_record CallRecord
		,startStopRecording StartStopRecording
		,leaveRecMessage LeaveRecMessage
		,manualCallOnChat ManualCallOnChat
		,callBackSurveyClient CallBackSurveyClient
		,callBackSurveyAgent CallBackSurveyAgent
		,funcEspDtmf FuncEspDtmf
		,sipHdrFormat SipHdrsCfg
		,dialPrefix DialPrefix
		,prefijo Prefix
		,dialOrder DialOrder
		,progDial ProgDial
		,cam_Descripcion CamDescription
		,cam_tNotas CamTnotas
		,cam_ocupado CamBusy
		,cam_noInt_ocupado CamNoIntBusy
		,cam_inter_ocupado CamInterBusy
		,cam_nocontesto CamNoAnswer
		,cam_noInt_nocontesto CamNoIntNoAnswer
		,cam_inter_nocontesto CamInterNoAnswer
		,(cam_inter_cancelled / 60) CamInterCancelled
		,cam_fax CamFax
		,cam_noInt_fax CamNoIntFax
		,cam_inter_fax CamInterFax
		,cam_modomanual CamModoManual
		,ANI
		,cam_StartTimerOnHangUp CamStartTimerOnHangUp
		,editableCallKey EditableCallKey
		,cam_tNoContesta CamTNoAnswer
		,iTipoDial CamIntensiveDialing
		,detectAnswerMachine DetectAnswerMachine
		,detectVoiceMail DetectVoiceMail
		,compliance Compliance
		,cam_inter_graba CamInterRecord
		,cam_noint_graba CamNoIntRecord
		,excCallBack ExcCallBack
		,cam_ShowCalifWnd CamShowCalifWnd
		,frame Frame
		,exitAssisted ExitAssistedDialMode
		,previewDiscard PreviewDiscard
		,CampType
		,conexionInfo ConexionInfo
		,connUser ConnUser
		,closeConversationTime CloseConversationTime
		,answerTimeoutClient MUTimeOutClient
		,allowFileAttachments AllowFileAttachments
		,CamTPreview
		,CAST(TimesPreview AS SMALLINT) TimesPreview
		,@numbers AS FreeNumbers
		,selectRotativeANI SelectRotativeANIManualCall
		,rotativeAlgo RotativeAlgo
		,autoStart AutoStart
		,messagingOrder MessagingOrder
		,timesDiscard TimesDiscard
		,recordHold RecordHold
		,zipCodeSchedule ZipCodeSchedule
		,RecordCalls RecordCalls
		,simultaneousRecs SimultaneousRecs
		,EditableContactData EditableContactData
		,internationalDialingPortsAssigned internationalDialingPortsAssigned
		FROM @AllCampaigns
		WHERE cam_id = @campID
		END
			'
        EXEC(@sql);

		SET @process = 'KR110000 DROP SP ccsp_RIAConfCamp'
        SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAConfCamp'')
		begin
			DROP PROCEDURE ccsp_RIAConfCamp;
		end'
        EXEC(@sql);

	    SET @process = 'KR110000 CREATE SP ccsp_RIAConfCamp'
        SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_RIAConfCamp] @User_id SMALLINT, @campID INT = NULL
		AS
		SET NOCOUNT ON

		DECLARE @tableExistsRec TABLE (
			camId INT PRIMARY KEY
			,existRec BIT
			)
		DECLARE @camByUser TABLE (
			camId INT PRIMARY KEY
			,isCheck BIT
			)
		DECLARE @camId INT
			,@id INT;
		DEClARE @intenationalDialingPorts bit;
		declare @tempInternationalCode int
 
		if((select COUNT(*) from ( select  IdCode from ccoDialers ccoDial inner join ccoDialerCamp ccoDialCamp on ccoDialCamp.dialer_id = ccoDial.dialer_id where ccoDialCamp.cam_id = @campID and ccoDial.DialingType=0  ) result ) > 0)
		BEGIN
			set @intenationalDialingPorts = 1
		END
		ElSE
		BEGIN
			set @intenationalDialingPorts = 0;
		END

		IF NOT EXISTS (
				SELECT *
				FROM ccUsers_Roles
				WHERE User_id = @User_id
					AND Rol_id = 7
				)
		BEGIN
			INSERT INTO @camByUser
			SELECT *
				,0
			FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
			WHERE @campID IS NULL
				OR cam_id = @campID
		END
		ELSE
		BEGIN
			INSERT INTO @camByUser
			SELECT cam_id
				,0
			FROM ccCamps
			WHERE (
					IDArea > 0
					OR IDArea IS NULL
					)
				AND (
					@campID IS NULL
					OR cam_id = @campID
					)
		END

		WHILE EXISTS (
				SELECT *
				FROM @camByUser
				WHERE isCheck = 0
				)
		BEGIN
			SELECT TOP 1 @camId = camId
			FROM @camByUser
			WHERE isCheck = 0

			IF EXISTS (
					SELECT cam_id
					FROM ccoCallsOut
					WHERE cam_id = @camId
					)
			BEGIN
				INSERT INTO @tableExistsRec
				VALUES (
					@camId
					,1
					)
			END
			ELSE
			BEGIN
				INSERT INTO @tableExistsRec
				VALUES (
					@camId
					,0
					)
			END

			UPDATE @camByUser
			SET isCheck = 1
			WHERE camId = @camId
		END

		SELECT a1.cam_id
			,cam_Descripcion
			,cam_tNotas
			,cast(cam_ocupado AS INT) AS cam_ocupado
			,cam_noInt_ocupado
			,cam_inter_ocupado
			,cast(cam_nocontesto AS INT) AS cam_nocontesto
			,cam_noInt_nocontesto
			,cam_inter_nocontesto
			,cast(cam_fax AS INT) AS cam_fax
			,cam_noInt_fax
			,cam_inter_fax
			,cast(cam_modomanual AS INT) AS cam_modomanual
			,ANI
			,cam_ShowCalifWnd
			,cam_StartTimerOnHangUp
			,editableCallKey
			,cam_tNoContesta
			,iTipoDial
			,detectAnswerMachine
			,detectVoiceMail
			,compliance
			,cam_inter_graba
			,cam_noint_graba
			,cast(progDial AS TINYINT) progDial
			,cast(excCallBack AS TINYINT) excCallBack
			,dialOrder
			,dialPrefix
			,dialPrefixMan
			,dialPrefixXfe
			,listenManualCall
			,stopRecording
			,cast(abandonCallback AS TINYINT) abandonCallback
			,a3.frame
			,a1.t_autoCB
			,a1.id_anilist
			,a1.tDialonWrapUp
			,dbo.fn_viewMode(@User_id, 10) viewMode
			,cam_maxqueue AS queSize
			,DNCScrub
			,callerIdDesc
			,timeZoneRule
			,callsBySurvey
			,ivrScript
			,surveyPctg
			,isnull(a1.call_record, 1) AS call_record
			,cast(startStopRecording AS TINYINT) startStopRecording
			,leaveRecMessage
			,manualCallOnChat
			,callBackSurveyAgent
			,callBackSurveyClient
			,CASE 
				WHEN surveycamid IS NULL
					OR surveycamid = 0
					THEN 0
				ELSE 1
				END isRelationSurvey
			,isnull(a1.funcEspDtmf, 0)
			,isnull(sipHdrFormat, '''') sipHdrFormat
			,cam_inter_cancelled
			,prefijo
			,enbleprefix = CASE 
				WHEN existRec = 0
					THEN 1
				ELSE 0
				END
			,isnull(exitAssisted, 0) exitAssisted
			,isnull(previewDiscard, 0) PreviewDiscard	
			,isnull(CampType, 0) CampType
			,isnull(contact.conexionInfo, '''') conexionInfo
			,isnull(contact.connUser, '''') connUser
			,isnull(contact.closeConversationTime, 0) closeConversationTime
			,isnull(contact.answerTimeoutClient, 0) answerTimeoutClient
			,isnull(contact.allowFileAttachments, 0) allowFileAttachments
			,isnull(selectRotativeANI, 0) selectRotativeANI
			,ISNULL(rotativeAlgo, 0) rotativeAlgo
			,isnull(autoStart, 0) autoStart
			,isnull(messagingOrder, 0) messagingOrder
			,ISNULL(cam_tPreview, 0) AS CamTPreview
			,ISNULL(timesPreview, 0) AS TimesPreview
			,isnull(timesDiscard, 0) TimesDiscard
			,ISNULL(recordHold, 0) recordHold
			,isnull(campsExtention.zipCodeSchedule, 0) ZipCodeSchedule
			,isnull(campsExtention.RecordCalls, 1) RecordCalls
			,isnull(campsExtention.simultaneousRecs, 1) simultaneousRecs
			,isnull(campsExtention.EditableContactData, 0) EditableContactData
			,@intenationalDialingPorts intenationalDialingPorts 
		FROM ccCamps a1
		INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
		INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
		INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
		LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
		LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
		ORDER BY cam_descripcion

		RETURN (0)

		SET NOCOUNT OFF
		'
        EXEC(@sql);

		SET @process = 'KR110000 DROP SP ccsp_RIALogPhones'
        SET @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_RIALogPhones'')
		begin
			DROP PROCEDURE ccsp_RIALogPhones;
		end'
        EXEC(@sql);

		SET @process = 'KR110000 CREATE SP ccsp_RIALogPhones'
        SET @sql = '
		CREATE procedure [dbo].[ccsp_RIALogPhones]
		@load_id int,
		@Type smallint,
		@GenCSV bit = 1, -- 0:100 / 1:todos
		@isKolob bit = 0,
		@PageIndex      INT = 0,
		@PageSize       INT = 0,
		@option SMALLINT = NULL
		as
		set nocount ON

		declare @CaseType varchar(2000), @sql nvarchar(MAX), @nType char(5), @MovType SMALLINT, @language int
		SELECT @language = cs.valor FROM dbo.ccSettings AS cs WHERE cs.setting_id = 27;
		declare @PageStart int,@PageEnd int

		select @CaseType = '''', @nType = right(''0000''+cast(@Type as varchar(5)), 5)

		if @nType like ''%____1%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov in (0,8)
			''

		if @nType like ''%___1_%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov in(-1,0,8) 
			''

		if @nType like ''%__1__%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 1 
			''

		if @nType like ''%_1___%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov = 1 
			''

		if @nType like ''%1____%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 2 ''

		if @CaseType = '''' and @nType <> 0
			return(0)

		if @nType like ''%____1%''
			select @CaseType = @CaseType + ''  or telefono<>'''''''' and crlp.tipoMov = 0''

		select @PageStart=@PageSize*(@PageIndex-1),@PageEnd=@PageSize*@PageIndex

		IF(@option = 1)
		BEGIN	
			SET @sql = ''SELECT count(*) AS listSize FROM (
		select crlp.load_id
		from ccRIALogPhones AS crlp 
		where crlp.load_id = @load_id'' 
		+ @CaseType +'') tmp '' +
		case @GenCSV when 0 then ''WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd'' else '''' end
					--EXEC(@sql);
			
				Exec sp_executesql @sql
						 , N''@PageStart int,@PageEnd int,@language int,@load_id int''
						 , @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id
					RETURN (0);
				END
				ELSE 
				BEGIN
						IF(@isKolob = 1)
						BEGIN

						declare @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200), @typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
						@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @typeUpdatedRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200), @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max);


						select @typeDescriptionPhoneBlocked=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-num''
						select @typeDescriptionPhoneUpdated=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-num''
						select @typeIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-incorrect-records''
						select @typeBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-records''
						select @typeDescriptionPhoneNotLoaded=translate from tableLangueDbLoader where languageId=@language and tag=''type-not-loaded-num''

						select @typeDescriptionPhoneBlackList=translate from tableLangueDbLoader where languageId=@language and tag=''description-dnc-list''
						select @descriptionIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-incorrect-records''
						select @descriptionBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-blocked-records''
						select @typeUpdatedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-records''
						select @descriptionInternationalPortNotFound=TRANSLATE from tableLangueDbLoader where languageId=@language and tag=''type-camp-no-international-port''


						select @column=translate from tableLangueDbLoader where languageId=@language and tag=''column-file-field''

						select @headerPhone=header_phone,@headerPhone2=header_phone2,@headerPhone3=header_phone3,@headerPhone4=header_phone4 
						,@headerPhone5=header_phone5
						from fileHeadersPhoneLoad where load_id=@load_id
			
							set @CaseType=case when @CaseType <> '''' then '' and ('' + substring(@CaseType, 5, len(@CaseType)) + '')'' else '''' END
							SET @sql = '';with result as(
							SELECT * FROM (select  
							ROW_NUMBER() OVER(ORDER BY crlp.cal_key ASC) AS RowNum,
							crlp.load_id,
							crlp.cal_key, 
							crlp.telefono AS phone,
							CASE
								WHEN crlp.tipoMov in (1,4)  THEN @typeDescriptionPhoneBlocked  
								WHEN crlp.tipoMov = 2 THEN @typeUpdatedRecords	
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @typeIncorrectRecords
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @typeBlockedRecords
								WHEN crlp.tipoMov in(-1,0) THEN @typeDescriptionPhoneNotLoaded
								WHEN crlp.tipoMov in(8) THEN @descriptionInternationalPortNotFound
								WHEN crlp.keyTranslate is not null THEN isnull(tlan.translate,crlp2.descTipoMov)
							ELSE 
								crlp2.descTipoMov  
							END AS Tipo,
							case when CHARINDEX('''':'''',crlp.motivo)=0 then 0 else
								convert(int,substring(crlp.motivo ,CHARINDEX('''':'''',crlp.motivo)-1 ,1))
							end
							 AS ColumnFile, 
							CASE  WHEN crlp.tipoMov = 2 THEN ''''N/A'''' 
									WHEN crlp.tipoMov in (1,4) THEN @typeDescriptionPhoneBlackList							  
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @descriptionIncorrectRecords
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @descriptionBlockedRecords
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-camp-no-international-port'''') THEN  @descriptionInternationalPortNotFound
									WHEN crlp.keyTranslate is not null THEN tlan.translate 
							ELSE crlp.motivo END AS motivo
							from ccRIALogPhones AS crlp 
							INNER JOIN dbo.ccRIACATLogPhones AS  crlp2 ON crlp.tipoMov = crlp2.tipoMov
							left join tableLangueDbLoader tlan on tlan.tag=crlp.keyTranslate and tlan.languageId=@language
							where crlp.load_id = @load_id '' 				
							+ @CaseType +'') tmp '' +
							case @GenCSV when 0 then '' WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd '' else '''' end +'' 
							) 
							select  crlp.RowNum,
							crlp.load_id,
							crlp.cal_key, 
							crlp.phone,
							crlp.Tipo,
							case when crlp.ColumnFile=1 then @headerPhone
							when crlp.ColumnFile=2 then @headerPhone2
							when crlp.ColumnFile=3 then @headerPhone3
							when crlp.ColumnFile=4 then @headerPhone4
							when crlp.ColumnFile=5 then @headerPhone5
							else '''''''' end ColumnFile,
							crlp.motivo
							from result crlp ''
			END
			ELSE
			BEGIN
				set @sql = ''select '' + case @GenCSV when 0 then ''top 100 '' else '''' end 
				+ ''load_id, cal_key, telefono, tipoMov, motivo from ccRIALogPhones AS crlp where load_id = @load_id '' 
				+ @CaseType
			END  
			--PRINT(@sql);



			Exec sp_executesql @sql, N''@PageStart int,@PageEnd int,@language int,@load_id int, @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200),
			@typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
			@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200)
			, @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max), @typeUpdatedRecords varchar(200)''
			, @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id,@column=@column,@typeDescriptionPhoneNotLoaded=@typeDescriptionPhoneNotLoaded
			,@typeDescriptionPhoneBlocked=@typeDescriptionPhoneBlocked,@typeDescriptionPhoneUpdated=@typeDescriptionPhoneUpdated,@typeDescriptionPhoneBlackList=@typeDescriptionPhoneBlackList
			,@typeBlockedRecords=@typeBlockedRecords,@typeIncorrectRecords=@typeIncorrectRecords,@descriptionBlockedRecords=@descriptionBlockedRecords,@descriptionIncorrectRecords=@descriptionIncorrectRecords,
			 @descriptionInternationalPortNotFound= @descriptionInternationalPortNotFound 
			,@headerPhone=@headerPhone,@headerPhone2=@headerPhone2,@headerPhone3=@headerPhone3,@headerPhone4=@headerPhone4,@headerPhone5=@headerPhone5,@typeUpdatedRecords=@typeUpdatedRecords
	
		return(0)
		END
		set nocount OFF'
        EXEC(@sql);

		SET @process = 'KR110000 DROP SP ccsp_GalateaGetRecordsImportStatus'
        SET @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_GalateaGetRecordsImportStatus'')
		begin
			DROP PROCEDURE ccsp_GalateaGetRecordsImportStatus;
		end'
        EXEC(@sql);

		SET @process = 'KR110000 CREATE SP ccsp_GalateaGetRecordsImportStatus'
        SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaGetRecordsImportStatus]
		-- @Type = 1:Detalle general de carga de registros | 2:Detalle específico de carga de registros | 3:Porcentaje de carga de registros
		@action tinyint, 
		@loadID int = NULL, 
		@userID smallint = NULL

		AS
		declare @today datetime
		select @today =convert(datetime, convert(varchar(11),getdate(),121),121)
		SET nocount ON
		if @action not IN (1,2,3)
		raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)

		if @action=1 -- Detalle general de carga de registros
		BEGIN
		if not exists(SELECT User_id FROM ccUsers WHERE TipoUser_id IN(2,6) AND Status>0 AND User_id=@userID)
		 BEGIN
		  raiserror(''ERROR. invalid user id'', 18, 1)
		  return(0)
		 END

		if exists (select * from ccUsers_Roles where User_id = @userID and Rol_id = (select Rol_id from ccRoles where Level = 7))
			BEGIN
				SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked+isnull(regsNotLoadedCp,0)+ISNULL(recordsNotLoadedPort,0) as regsNotLoaded, state, loadDate	
				FROM ccRIALoading riaLoad
				JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
				WHERE 
				loadDate>=@today and loadType = 0
				ORDER BY riaLoad.loadDate DESC
			END
		else
			BEGIN
				SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked+isnull(regsNotLoadedCp,0)+ISNULL(recordsNotLoadedPort,0) as regsNotLoaded, state, loadDate
		
				FROM ccRIALoading riaLoad
				JOIN ccSupervisorCam superCam ON riaLoad.cam_id = superCam.cam_id
				JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
				WHERE 
				loadDate>=@today AND
				superCam.user_id = @userID
				AND superCam.tipo = 1
				ORDER BY riaLoad.loadDate DESC
			END

		return(0)
		END

		if @action=2 -- Detalle específico de carga de registros
		BEGIN
		if not exists(SELECT load_id FROM ccRIALoading)
		 BEGIN
		  raiserror(''ERROR. invalid template ID'', 18, 1)
		  return(0)
		 END

		  SELECT regsLoaded, alreadyLoaded, regsBlocked, regsNotLoaded,
				 telsLoaded, telsBlocked, telsNotLoaded, isnull(regsNotLoadedCp,0) as regsNotLoadedCp
				 , isnull(telsNotLoadedCp,0) as telsNotLoadedCp, ISNULL(recordsNotLoadedPort,0) as recordsNotLoadedPort, ISNULL(phonesNotLoadedPort, 0) as phonesNotLoadedPort
		  FROM ccRIALoading
		  WHERE load_id  = @loadID

		END

		if @action=3 -- Porcentaje de carga de registros
		BEGIN
		if not exists(SELECT load_id FROM ccRIALoading)
		 BEGIN
		  raiserror(''ERROR. invalid load ID'', 18, 1)
		  return(0)
		 END

		  SELECT state, pctg
		  FROM ccRIALoading
		  WHERE load_id  = @loadID

		END
		SET nocount off'
        EXEC(@sql);

		SET @process = 'KR110000 INSERT INTO tableLangueDbLoader tag=type-camp-no-international-port, languageId=0'
        SET @sql = '
		if not exists(select tag from tableLangueDbLoader where tag = ''type-camp-no-international-port'' and languageId=0)
		begin
			insert into tableLangueDbLoader (languageId,tag, translate) values (0,''type-camp-no-international-port'',''Puerto internacional no encontrado'')
		end'
        EXEC(@sql);

		
		SET @process = 'KR110000 INSERT INTO tableLangueDbLoader tag=type-camp-no-international-port, languageId=1'
        SET @sql = '
		if not exists(select tag from tableLangueDbLoader where tag = ''type-camp-no-international-port'' and languageId=1)
		begin
			insert into tableLangueDbLoader (languageId,tag, translate) values (1,''type-camp-no-international-port'',''International port not found'')
		end'
        EXEC(@sql);

		SET @process = 'KR110000 INSERT INTO tableLangueDbLoader tag = type-camp-no-international-port, languageId=2'
        SET @sql = '
		if not exists(select tag from tableLangueDbLoader where tag = ''type-camp-no-international-port'' and languageId=2)
		begin
			insert into tableLangueDbLoader (languageId,tag, translate) values (2,''type-camp-no-international-port'',''Porta internacional não encontrada'')
		end'
        EXEC(@sql);

		
		SET @process = 'KR110000 INSERT INTO ccGalateaIdentifiers'
        SET @sql = '
		if not exists(select Description from ccGalateaIdentifiers where Description = ''LOAD_INTERNATIONAL_RECORDS'')
		begin
			insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''LOAD_INTERNATIONAL_RECORDS'',''Registros internacionales'',''International records'',''Registros internacionais'')
		end'
        EXEC(@sql);

		SET @process = 'KR110000 INSERT INTO  ccRIACATLogPhones tipoMov = 8'
        SET @sql = '
		if not exists(select tipoMov from ccRIACATLogPhones where tipoMov = 8)
		begin
			insert into ccRIACATLogPhones (tipoMov,descTipoMov) values (8,''No cargados sin puertos'')
		end
 '
        EXEC(@sql);

		      
       ----------------------------------------------------- END Fri----------------------------------------------------------------

        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

        COMMIT TRAN
    END TRY

    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

        RAISERROR (@errorGenerated, 11, 1)

        ROLLBACK TRAN
    END CATCH
END 
