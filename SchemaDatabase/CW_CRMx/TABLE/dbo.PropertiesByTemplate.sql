CREATE TABLE [dbo].[PropertiesByTemplate](	  [idTemplate] INT NOT NULL	, [countIds] XML NOT NULL DEFAULT('<CountIDComponents>
		<label id="1"/>
		<textInput id="1"/>
		<numeric id="1"/>
		<time id="1"/>
		<textArea id="1"/>
		<comboBox id="1"/>
		<calendar id="1"/>
		<image id="1"/>
		<checkBox id="1"/>
		<radioButton id="1"/>
		</CountIDComponents>')	, CONSTRAINT [PK__PropertiesByTemp__0E6E26BF] PRIMARY KEY ([idTemplate] ASC))ALTER TABLE [dbo].[PropertiesByTemplate] WITH CHECK ADD CONSTRAINT [fk_idTemplate] FOREIGN KEY([idTemplate]) REFERENCES [dbo].[CRMxTemplates] ([id]) ON DELETE CASCADEALTER TABLE [dbo].[PropertiesByTemplate] CHECK CONSTRAINT [fk_idTemplate]