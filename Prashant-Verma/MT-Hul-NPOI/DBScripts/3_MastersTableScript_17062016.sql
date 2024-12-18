
/****** Object:  Table [dbo].[mtAuditTrailMasterData]    Script Date: 06/17/2016 11:33:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtAuditTrailMasterData](
	[Id] [uniqueidentifier] NOT NULL,
	[Entity] [varchar](150) NULL,
	[KeyName] [varchar](150) NULL,
	[Key] [varchar](50) NULL,
	[Data] [varchar](8000) NULL,
	[Operation] [varchar](1) NULL,
	[UpdatedDate] [datetime] NULL,
	[UpdatedBy] [varchar](200) NULL,
 CONSTRAINT [PK_mtAuditTrailMasterData] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[mtAuditTrailMasterData] ADD  CONSTRAINT [DF_mtAuditTrailMasterData_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO



/****** Object:  Table [dbo].[MTTierBasedTOTRate]    Script Date: 06/17/2016 10:37:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MTTierBasedTOTRate](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ChainName] [nvarchar](100) NOT NULL,
	[GroupName] [nvarchar](100) NOT NULL,
	[OutletTier] [nvarchar](100) NOT NULL,
	[ColorNonColor] [nvarchar](100) NOT NULL,
	[PriceList] [nvarchar](6) NOT NULL,
	[OnInvoiceRate] [decimal](18, 5) NULL,
	[OffInvoiceMthlyRate] [decimal](18, 5) NULL,
	[OffInvoiceQtrlyRate] [decimal](18, 5) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NULL,
 CONSTRAINT [PK_MTTierBasedTOTRate_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[mtServiceTaxRateMaster]    Script Date: 06/17/2016 10:37:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[mtServiceTaxRateMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ChainName] [nvarchar](255) NULL,
	[GroupName] [nvarchar](255) NULL,
	[Rate] [decimal](5, 4) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NULL,
 CONSTRAINT [PK__mtServic__3214EC07970A3FA0] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[mtSalesTaxMaster]    Script Date: 06/17/2016 10:37:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[mtSalesTaxMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TaxCode] [nvarchar](255) NULL,
	[StateCode] [nvarchar](255) NULL,
	[SalesTaxRate] [decimal](5, 5) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NULL,
 CONSTRAINT [PK__mtSalesTax__3214EC07970A3FA0] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO


/****** Object:  Table [dbo].[mtOnInvoiceValueConfig]    Script Date: 06/17/2016 11:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mtOnInvoiceValueConfig](
	[Id] [int] NOT NULL,
	[StateCode] [nvarchar](4) NULL,
	[IsNetSalesValueAppl] [bit] NULL,
 CONSTRAINT [PK_mtOnInvoiceValueConfig] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Default [DF_mtOnInvoiceValueConfig_IsNetSalesValueAppl]    Script Date: 06/17/2016 11:18:52 ******/
ALTER TABLE [dbo].[mtOnInvoiceValueConfig] ADD  CONSTRAINT [DF_mtOnInvoiceValueConfig_IsNetSalesValueAppl]  DEFAULT ((0)) FOR [IsNetSalesValueAppl]
GO

/****** Object:  Table [dbo].[mtPriceListMaster]    Script Date: 06/17/2016 10:37:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mtPriceListMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PriceList] [nvarchar](50) NULL,
	[CreatedBy] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[mtGLMaster]    Script Date: 06/17/2016 10:37:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mtGLMaster](
	[Id] [int] NOT NULL,
	[DbCr] [nvarchar](2) NULL,
	[GLAccount] [nvarchar](15) NULL,
 CONSTRAINT [PK_mtGLMaster] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[mtChainNameMaster]    Script Date: 06/17/2016 10:37:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[mtChainNameMaster](
	[Id] [int] NOT NULL,
	[ChainName] [nvarchar](100) NULL,
	[IsHuggiesAppl] [bit] NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NOT NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[mtAdditionalMarginMaster]    Script Date: 06/17/2016 10:37:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[mtAdditionalMarginMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[RSCode] [nvarchar](255) NULL,
	[RSName] [nvarchar](255) NULL,
	[ChainName] [nvarchar](255) NULL,
	[GroupName] [nvarchar](255) NULL,
	[PriceList] [nvarchar](100) NULL,
	[Percentage] [decimal](5, 3) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NULL,
 CONSTRAINT [PK__mtAdditionalMargin__3214EC07970A3FA0] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Default [DF_mtAdditionalMarginMaster_CreatedAt]    Script Date: 06/17/2016 10:37:05 ******/
ALTER TABLE [dbo].[mtAdditionalMarginMaster] ADD  CONSTRAINT [DF_mtAdditionalMarginMaster_CreatedAt]  DEFAULT (getdate()) FOR [CreatedAt]
GO
/****** Object:  Default [DF_mtServiceTaxMaster_CreatedAt]    Script Date: 06/17/2016 10:37:05 ******/
ALTER TABLE [dbo].[mtServiceTaxRateMaster] ADD  CONSTRAINT [DF_mtServiceTaxMaster_CreatedAt]  DEFAULT (getdate()) FOR [CreatedAt]
GO
/****** Object:  Default [DF_MTTierBasedTOTRate_CreatedAt]    Script Date: 06/17/2016 10:37:05 ******/
ALTER TABLE [dbo].[MTTierBasedTOTRate] ADD  CONSTRAINT [DF_MTTierBasedTOTRate_CreatedAt]  DEFAULT (getdate()) FOR [CreatedAt]
GO





/****** Object:  StoredProcedure [dbo].[Update_mtAdditionalMarginMaster]    Script Date: 06/17/2016 10:45:54 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_mtAdditionalMarginMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_mtAdditionalMarginMaster]
GO

/****** Object:  UserDefinedTableType [dbo].[mtAdditionalMarginMasterType]    Script Date: 06/17/2016 10:46:54 ******/
IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'mtAdditionalMarginMasterType' AND ss.name = N'dbo')
DROP TYPE [dbo].[mtAdditionalMarginMasterType]
GO


/****** Object:  UserDefinedTableType [dbo].[mtAdditionalMarginMasterType]    Script Date: 06/17/2016 10:46:54 ******/
CREATE TYPE [dbo].[mtAdditionalMarginMasterType] AS TABLE(
	[RSCode] [nvarchar](255) NULL,
	[RSName] [nvarchar](255) NULL,
	[ChainName] [nvarchar](255) NULL,
	[GroupName] [nvarchar](255) NULL,
	[PriceList] [nvarchar](100) NULL,
	[Percentage] [decimal](5, 3) NULL
)
GO




/****** Object:  StoredProcedure [dbo].[Update_mtAdditionalMarginMaster]    Script Date: 06/17/2016 10:45:54 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[Update_mtAdditionalMarginMaster]
      @tblAdditionalMarginMaster mtAdditionalMarginMasterType READONLY,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


	   INSERT INTO mtAuditTrailMasterData	  
	  select newid() Id, 'AdditionalMarginMaster' Entity,'Id' KeyName,c1.Id as [Key], 
	  'RS Code' + ' : ' + c1.RSCode +
	  ' ^ RS Name' + ' : ' + c1.RSName + ' | ' + c2.RSName +
	  ' ^ Chain Name' + ' : ' + c1.ChainName +
	  ' ^ Group Name' + ' : ' + c1.GroupName +
	  ' ^ Price List' + ' : ' + c1.PriceList +
	  ' ^ Percentage' + ' : ' + CONVERT(varchar(200),c1.Percentage) + ' | ' + CONVERT(varchar(200),c2.Percentage) as Data,
	  'U' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from mtAdditionalMarginMaster c1, @tblAdditionalMarginMaster c2
	 where c1.RSCode=LTRIM(RTRIM(c2.RSCode)) AND c1.ChainName=LTRIM(RTRIM(c2.ChainName)) AND c1.GroupName=LTRIM(RTRIM(c2.GroupName)) AND c1.PriceList=LTRIM(RTRIM(c2.PriceList))
	 And (c1.RSName <> c2.RSName OR c1.Percentage <> c2.Percentage)


      MERGE INTO mtAdditionalMarginMaster c1
      USING @tblAdditionalMarginMaster c2
      ON c1.RSCode=ltrim(rtrim(c2.RSCode)) AND c1.ChainName=ltrim(rtrim(c2.ChainName)) AND c1.GroupName=ltrim(rtrim(c2.GroupName)) AND c1.PriceList=ltrim(rtrim(c2.PriceList))	 
      WHEN MATCHED THEN
		UPDATE SET
             c1.RSName = ltrim(rtrim(c2.RSName ))         
            ,c1.Percentage = c2.Percentage			
			,c1.UpdatedAt = getdate()
			,c1.UpdatedBy = @user
			,c1.Operation = 'U'
		WHEN NOT MATCHED THEN
			INSERT VALUES(ltrim(rtrim( c2.RSCode)),ltrim(rtrim(c2.RSName)),ltrim(rtrim(c2.ChainName)),ltrim(rtrim(c2.GroupName)), ltrim(rtrim(c2.PriceList)), c2.Percentage,getdate(),@user,null,null,'I');
    


COMMIT
   END TRY
    --BEGIN CATCH
    -- 
      
    --END CATCH
    BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
                ROLLBACK
END CATCH;
END



GO




/****** Object:  StoredProcedure [dbo].[Update_mtSalesTaxMaster]    Script Date: 06/17/2016 10:45:48 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_mtSalesTaxMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_mtSalesTaxMaster]
GO


/****** Object:  UserDefinedTableType [dbo].[mtSalesTaxMasterType]    Script Date: 06/17/2016 10:47:08 ******/
IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'mtSalesTaxMasterType' AND ss.name = N'dbo')
DROP TYPE [dbo].[mtSalesTaxMasterType]
GO



/****** Object:  UserDefinedTableType [dbo].[mtSalesTaxMasterType]    Script Date: 06/17/2016 10:47:08 ******/
CREATE TYPE [dbo].[mtSalesTaxMasterType] AS TABLE(
	[TaxCode] [nvarchar](255) NULL,
	[StateCode] [nvarchar](255) NULL,
	[SalesTaxRate] [decimal](5, 5) NULL
)
GO




/****** Object:  StoredProcedure [dbo].[Update_mtSalesTaxMaster]    Script Date: 06/17/2016 10:45:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[Update_mtSalesTaxMaster]
      @tblSalesTaxMaster mtSalesTaxMasterType READONLY,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
       INSERT INTO mtAuditTrailMasterData	  
	  select newid() Id, 'SalesTaxMaster' Entity,'Id' KeyName,c1.Id as [Key], 
	  'Tax Code' + ' : ' + c1.TaxCode +
	  ' ^ State Code' + ' : ' + c1.StateCode +
	  ' ^ Sales Tax Rate' + ' : ' + CONVERT(varchar(200),c1.SalesTaxRate) + ' | ' + CONVERT(varchar(200),c2.SalesTaxRate) as Data,
	  'U' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from mtSalesTaxMaster c1, @tblSalesTaxMaster c2
	 where c1.TaxCode=LTRIM(RTRIM(c2.TaxCode)) AND c1.StateCode=LTRIM(RTRIM(c2.StateCode))
	 And (c1.SalesTaxRate <> c2.SalesTaxRate )


      MERGE INTO mtSalesTaxMaster c1
      USING @tblSalesTaxMaster c2
      ON c1.TaxCode=LTRIM(RTRIM(c2.TaxCode)) and c1.StateCode=LTRIM(RTRIM(c2.StateCode))
      WHEN MATCHED THEN
      UPDATE SET c1.TaxCode = LTRIM(RTRIM(c2.TaxCode))
            ,c1.StateCode = LTRIM(RTRIM(c2.StateCode))
            ,c1.SalesTaxRate = c2.SalesTaxRate
			,c1.UpdatedAt = getdate()
			,c1.UpdatedBy = @user
			,c1.Operation = 'U'
      WHEN NOT MATCHED THEN
   INSERT VALUES(LTRIM(RTRIM(c2.TaxCode)),LTRIM(RTRIM(c2.StateCode)),c2.SalesTaxRate,getdate(),@user,null,null,'I');

COMMIT
    END TRY
    --BEGIN CATCH
    -- 
      
    --END CATCH
    BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
                ROLLBACK
END CATCH;
END




GO




/****** Object:  StoredProcedure [dbo].[Update_mtServiceTaxRateMaster]    Script Date: 06/17/2016 10:45:40 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_mtServiceTaxRateMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_mtServiceTaxRateMaster]
GO



/****** Object:  UserDefinedTableType [dbo].[mtServiceTaxRateMasterType]    Script Date: 06/17/2016 10:47:04 ******/
IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'mtServiceTaxRateMasterType' AND ss.name = N'dbo')
DROP TYPE [dbo].[mtServiceTaxRateMasterType]
GO


/****** Object:  UserDefinedTableType [dbo].[mtServiceTaxRateMasterType]    Script Date: 06/17/2016 10:47:04 ******/
CREATE TYPE [dbo].[mtServiceTaxRateMasterType] AS TABLE(
	[ChainName] [nvarchar](255) NULL,
	[GroupName] [nvarchar](255) NULL,
	[Rate] [decimal](5, 2) NULL
)
GO



/****** Object:  StoredProcedure [dbo].[Update_mtServiceTaxRateMaster]    Script Date: 06/17/2016 10:45:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[Update_mtServiceTaxRateMaster]
      @tblServiceTaxRateMaster mtServiceTaxRateMasterType READONLY,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
	   INSERT INTO mtAuditTrailMasterData	  
	  select newid() Id, 'ServiceTaxRateMaster' Entity,'Id' KeyName,c1.Id as [Key], 
	  'Chain Name' + ' : ' + c1.ChainName +
	  ' ^ Group Name' + ' : ' + c1.GroupName +
	  ' ^ Rate' + ' : ' + CONVERT(varchar(200),c1.Rate) + ' | ' + CONVERT(varchar(200),c2.Rate) as Data,
	  'U' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from mtServiceTaxRateMaster c1, @tblServiceTaxRateMaster c2
	 where c1.ChainName=LTRIM(RTRIM(c2.ChainName)) AND c1.GroupName=LTRIM(RTRIM(c2.GroupName)) 
	 And (c1.Rate <> c2.Rate)

      MERGE INTO mtServiceTaxRateMaster c1
      USING @tblServiceTaxRateMaster c2
      ON c1.ChainName=LTRIM(RTRIM(c2.ChainName)) and c1.GroupName=LTRIM(RTRIM(c2.GroupName))
       WHEN MATCHED THEN
      UPDATE SET c1.Rate = c2.Rate
   ,c1.UpdatedAt = getdate()
   ,c1.UpdatedBy = @user
   ,c1.Operation = 'U'
      WHEN NOT MATCHED THEN
   INSERT VALUES(LTRIM(RTRIM(c2.ChainName)),LTRIM(RTRIM(c2.GroupName)),c2.Rate,getdate(),@user,NULL,NULL,'I');
COMMIT
   END TRY
    --BEGIN CATCH
    -- 
      
    --END CATCH
    BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
                ROLLBACK
END CATCH;
END




GO



/****** Object:  StoredProcedure [dbo].[Update_mtTierBasedTOTRate]    Script Date: 06/17/2016 10:45:35 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_mtTierBasedTOTRate]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_mtTierBasedTOTRate]
GO



/****** Object:  UserDefinedTableType [dbo].[mtTierBasedTOTRateType]    Script Date: 06/17/2016 10:46:58 ******/
IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'mtTierBasedTOTRateType' AND ss.name = N'dbo')
DROP TYPE [dbo].[mtTierBasedTOTRateType]
GO


/****** Object:  UserDefinedTableType [dbo].[mtTierBasedTOTRateType]    Script Date: 06/17/2016 10:46:58 ******/
CREATE TYPE [dbo].[mtTierBasedTOTRateType] AS TABLE(
	[ChainName] [nvarchar](100) NOT NULL,
	[GroupName] [nvarchar](100) NOT NULL,
	[OutletTier] [nvarchar](100) NOT NULL,
	[ColorNonColor] [nvarchar](100) NOT NULL,
	[PriceList] [nvarchar](6) NOT NULL,
	[OnInvoiceRate] [decimal](18, 4) NULL,
	[OffInvoiceMthlyRate] [decimal](18, 4) NULL,
	[OffInvoiceQtrlyRate] [decimal](18, 4) NULL
)
GO




/****** Object:  StoredProcedure [dbo].[Update_mtTierBasedTOTRate]    Script Date: 06/17/2016 10:45:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[Update_mtTierBasedTOTRate]
      @tblTierBasedTOTRate mtTierBasedTOTRateType READONLY,
      @user nvarchar(100)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
      
	   INSERT INTO mtAuditTrailMasterData	  
	  select newid() Id, 'TierBasedTOTRate' Entity,'Id' KeyName,c1.Id as [Key], 
	  ' Chain Name' + ' : ' + c1.ChainName +
	  ' ^ Group Name' + ' : ' + c1.GroupName +
	  ' ^ Outlet Tier' + ' : ' + c1.OutletTier +
	  ' ^ Color Non-Color' + ' : ' + c1.ColorNonColor +
	  ' ^ Price List' + ' : ' + c1.PriceList +
	  ' ^ On Invoice Rate' + ' : ' + CONVERT(varchar(200),c1.OnInvoiceRate) + ' | ' + CONVERT(varchar(200),c2.OnInvoiceRate)+
	  ' ^ Off Invoice Mthly Rate' + ' : ' + CONVERT(varchar(200),c1.OffInvoiceMthlyRate) + ' | ' + CONVERT(varchar(200),c2.OffInvoiceMthlyRate)+ 
	  ' ^ Off Invoice Qtrly Rate' + ' : ' + CONVERT(varchar(200),c1.OffInvoiceQtrlyRate) + ' | ' + CONVERT(varchar(200),c2.OffInvoiceQtrlyRate)as Data,
	  'U' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from MTTierBasedTOTRate c1, @tblTierBasedTOTRate c2
	 where c1.ChainName=LTRIM(RTRIM(c2.ChainName)) AND c1.GroupName=LTRIM(RTRIM(c2.GroupName)) AND c1.OutletTier=LTRIM(RTRIM(c2.OutletTier)) AND c1.ColorNonColor=LTRIM(RTRIM(c2.ColorNonColor)) AND c1.PriceList=LTRIM(RTRIM(c2.PriceList))
	 And (c1.OnInvoiceRate <> c2.OnInvoiceRate OR c1.OffInvoiceMthlyRate <> c2.OffInvoiceMthlyRate
	 OR c1.OffInvoiceQtrlyRate <> c2.OffInvoiceQtrlyRate)

      
      MERGE INTO MTTierBasedTOTRate c1
      USING @tblTierBasedTOTRate c2
      ON c1.ChainName = LTRIM(RTRIM(c2.ChainName))
            and c1.GroupName = LTRIM(RTRIM(c2.GroupName))
            and c1.OutletTier = LTRIM(RTRIM(c2.OutletTier))
            and c1.ColorNonColor = LTRIM(RTRIM(c2.ColorNonColor))
            and c1.PriceList = LTRIM(RTRIM(c2.PriceList))
      WHEN MATCHED THEN
      UPDATE SET c1.ChainName = LTRIM(RTRIM(c2.ChainName))
            ,c1.GroupName = LTRIM(RTRIM(c2.GroupName))
            ,c1.OutletTier = LTRIM(RTRIM(c2.OutletTier))
            ,c1.ColorNonColor = LTRIM(RTRIM(c2.ColorNonColor))
            ,c1.PriceList = LTRIM(RTRIM(c2.PriceList))
            ,c1.OnInvoiceRate = c2.OnInvoiceRate
            ,c1.OffInvoiceMthlyRate = c2.OffInvoiceMthlyRate
            ,c1.OffInvoiceQtrlyRate = c2.OffInvoiceQtrlyRate
			,c1.UpdatedAt = Getdate()
			,c1.UpdatedBy = @user
			,c1.Operation = 'U'
      WHEN NOT MATCHED THEN
   INSERT VALUES(LTRIM(RTRIM(c2.ChainName)),LTRIM(RTRIM(c2.GroupName)),LTRIM(RTRIM(c2.OutletTier)),LTRIM(RTRIM(c2.ColorNonColor)), LTRIM(RTRIM(c2.PriceList)), c2.OnInvoiceRate,c2.OffInvoiceMthlyRate,c2.OffInvoiceQtrlyRate,Getdate(),@user,NULL,NULL,'I');

COMMIT
    END TRY
    --BEGIN CATCH
    -- 
      
    --END CATCH
    BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
                ROLLBACK
END CATCH;
END




GO


