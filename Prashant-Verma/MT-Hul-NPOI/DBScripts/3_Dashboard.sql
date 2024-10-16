/****** Object:  Table [dbo].[mtStepMaster]    Script Date: 06/11/2016 14:47:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mtStepMaster](
	[StepId] [nvarchar](20) NULL,
	[Sequence] [int] NULL,
	[Name] [nvarchar](50) NULL,
	[Type] [nvarchar](10) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[mtMOCWiseStepDetails]    Script Date: 06/11/2016 14:47:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mtMOCWiseStepDetails](
	[Id] [uniqueidentifier] NOT NULL,
	[MonthId] [int] NULL,
	[Year] [int] NULL,
	[StepId] [nvarchar](20) NULL,
	[Status] [nvarchar](20) NULL,
	[ExecutionTimes] [int] NULL,
	[CreatedAt] [datetime] NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](100) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[mtMOCStatus]    Script Date: 06/11/2016 14:47:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mtMOCStatus](
	[Id] [uniqueidentifier] NOT NULL,
	[MonthId] [int] NULL,
	[Year] [int] NULL,
	[Status] [nvarchar](50) NULL,
	[CreatedAt] [datetime] NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](100) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[mtMasterDetails]    Script Date: 06/11/2016 14:47:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mtMasterDetails](
	[StepId] [nvarchar](20) NULL,
	[DetailedStep] [nvarchar](50) NULL,
	[Status] [nvarchar](20) NULL,
	[CreatedAt] [datetime] NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](100) NULL
) ON [PRIMARY]
GO


/****** Object:  StoredProcedure [dbo].[Update_Dashboard_SingleStepStatus]    Script Date: 06/18/2016 13:44:01 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_Dashboard_SingleStepStatus]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_Dashboard_SingleStepStatus]
GO



/****** Object:  StoredProcedure [dbo].[Update_Dashboard_SingleStepStatus]    Script Date: 06/18/2016 13:44:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Update_Dashboard_SingleStepStatus]
      @mocMonthId int,@mocYear int,@stepId varchar(20)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
      UPDATE mtMOCWiseStepDetails
SET Status='Done'
WHERE MonthId=@mocMonthId AND [YEAR]=@mocYear AND StepId=@stepId;

declare @Sequence int;
set @Sequence = (select Sequence from mtStepMaster where StepId=@stepId)
declare @NextSequence int;
set @NextSequence=(@Sequence+1)
declare @NextStepId varchar(20);
set @NextStepId = (select StepId from mtStepMaster where Sequence=@NextSequence)

IF @stepId='JV'
BEGIN
UPDATE mtMOCWiseStepDetails
SET Status='Started'
WHERE MonthId=@mocMonthId AND [YEAR]=@mocYear AND StepId=@NextStepId;

UPDATE mtMOCWiseStepDetails
SET Status='Started'
WHERE MonthId=@mocMonthId AND [YEAR]=@mocYear AND StepId='CLSMOC';
END
ELSE
BEGIN
UPDATE mtMOCWiseStepDetails
SET Status='Started'
WHERE MonthId=@mocMonthId AND [YEAR]=@mocYear AND StepId=@NextStepId;
END                
  
  COMMIT
    END TRY
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



/****** Object:  StoredProcedure [dbo].[Update_Dashboard_MultipleStepStatus]    Script Date: 06/11/2016 14:47:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Update_Dashboard_MultipleStepStatus]
      @mocMonthId int,@mocYear int,@stepId varchar(20),@detailedStepId varchar(50)
AS

BEGIN
	declare @CheckStepStatus varchar(20);
	set @CheckStepStatus = (select [Status] from mtMOCWiseStepDetails where StepId=@stepId)
	IF @CheckStepStatus<>'Done'
	BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
      UPDATE mtMasterDetails
SET Status='Done'
WHERE StepId=@stepId AND DetailedStep=@detailedStepId;

declare @StepStatus varchar(50);
SET @StepStatus = (SELECT
    CASE
        WHEN EXISTS(
            SELECT 1
            FROM mtMasterDetails
            WHERE StepId=@stepId AND Status='NotStarted'
        ) THEN 0
        ELSE 1
    END)
    
    if @StepStatus=1
    BEGIN
     UPDATE mtMOCWiseStepDetails
	 SET Status='Done'
	 WHERE StepId=@stepId AND MonthId=@mocMonthId AND [YEAR]=@mocYear;
	END
	
	declare @UPMStepStatus varchar(20);
	set @UPMStepStatus = (select [Status] from mtMOCWiseStepDetails where StepId='UPM')
	
	declare @UPPMStepStatus varchar(20);
	set @UPPMStepStatus = (select [Status] from mtMOCWiseStepDetails where StepId='UPPM')
	
	if @UPMStepStatus='Done' AND @UPPMStepStatus='Done'
    BEGIN
     UPDATE mtMOCWiseStepDetails
	 SET Status='Started'
	 WHERE StepId='UPSEC' AND MonthId=@mocMonthId AND [YEAR]=@mocYear;
	END
  
  COMMIT
    END TRY
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
END
GO

/****** Object:  StoredProcedure [dbo].[mtCreate_newMOCDetails_FirstTime]    Script Date: 06/18/2016 13:45:51 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtCreate_newMOCDetails_FirstTime]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtCreate_newMOCDetails_FirstTime]
GO



/****** Object:  StoredProcedure [dbo].[mtCreate_newMOCDetails_FirstTime]    Script Date: 06/18/2016 13:45:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[mtCreate_newMOCDetails_FirstTime]
      @mocMonthId int,@mocYear int,@createdAt datetime,@createdBy varchar(100)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
                 Insert into mtMOCStatus (Id, MonthId,[Year],[Status],CreatedAt,CreatedBy,UpdatedAt,UpdatedBy) VALUES (NEWID(), @mocMonthId,@mocYear,'Open',@createdAt,@createdBy,null,null)
                 
                 Insert into mtMOCWiseStepDetails (Id, MonthId,[Year],StepId,[Status],ExecutionTimes,CreatedAt,CreatedBy,UpdatedAt,UpdatedBy) 
                 VALUES (NEWID(), @mocMonthId,@mocYear,'UPM','Started',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'UPPM','Started',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'UPSEC','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'GSV','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'PVSION','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'JV','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'ExportJV','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'CLSMOC','NotStarted',0,@createdAt,@createdBy,null,null)
                 
                 Insert into mtMasterDetails (StepId,DetailedStep,[Status],CreatedAt,CreatedBy,UpdatedAt,UpdatedBy)
                 VALUES ('UPM','CUSTGRP','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPM','SKU','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPM','SALESTAXRATE','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','OUTLETMASTER','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','ADDMARGIN','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','SERVICETAX','Done',@createdAt,@createdBy,null,null),
                 ('UPPM','HUGGIESBAEPACK','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','CLUSTERRSCODE','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','TIERBASEDTOT','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','SUBCATMAPPING','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','SUBCATBASEDTOT','NotStarted',@createdAt,@createdBy,null,null)
  
  COMMIT
    END TRY
    BEGIN CATCH
      ROLLBACK
    END CATCH
END

GO



/****** Object:  StoredProcedure [dbo].[mtCreate_newMOCDetails]    Script Date: 06/11/2016 14:47:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[mtCreate_newMOCDetails]
      @mocMonthId int,@mocYear int,@createdAt datetime,@createdBy varchar(100),@lastmocMonthId int,@lastmocYear int
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
                 Insert into mtMOCStatus (Id, MonthId,[Year],[Status],CreatedAt,CreatedBy,UpdatedAt,UpdatedBy) VALUES (NEWID(), @mocMonthId,@mocYear,'Open',@createdAt,@createdBy,null,null)
                 declare @UPMStatus varchar(100);
                 set @UPMStatus = (select [Status] from mtMOCWiseStepDetails where MonthId=@lastmocMonthId and [YEAR]=@lastmocYear and StepId='UPM')
                 declare @UPPMStatus varchar(100);
                 set @UPPMStatus = (select [Status] from mtMOCWiseStepDetails where MonthId=@lastmocMonthId and [YEAR]=@lastmocYear and StepId='UPPM')
                 
                 Insert into mtMOCWiseStepDetails (Id, MonthId,[Year],StepId,[Status],ExecutionTimes,CreatedAt,CreatedBy,UpdatedAt,UpdatedBy) 
                 VALUES (NEWID(), @mocMonthId,@mocYear,'UPM',@UPMStatus,0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'UPPM',@UPPMStatus,0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'UPSEC','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'GSV','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'PVSION','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'JV','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'ExportJV','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'CLSMOC','NotStarted',0,@createdAt,@createdBy,null,null)
  
  COMMIT
    END TRY
    BEGIN CATCH
      ROLLBACK
    END CATCH
END
GO


INSERT [dbo].[mtStepMaster] ([StepId], [Sequence], [Name], [Type]) VALUES (N'UPM', 1, N'Upload Masters', N'MS')
INSERT [dbo].[mtStepMaster] ([StepId], [Sequence], [Name], [Type]) VALUES (N'UPPM', 1, N'Upload Provision Masters', N'MS')
INSERT [dbo].[mtStepMaster] ([StepId], [Sequence], [Name], [Type]) VALUES (N'UPSEC', 2, N'Upload Sec Sales', N'EANEXT')
INSERT [dbo].[mtStepMaster] ([StepId], [Sequence], [Name], [Type]) VALUES (N'GSV', 3, N'Calculate GSV', N'EANEXT')
INSERT [dbo].[mtStepMaster] ([StepId], [Sequence], [Name], [Type]) VALUES (N'PVSION', 4, N'Calculate Provision', N'EANEXT')
INSERT [dbo].[mtStepMaster] ([StepId], [Sequence], [Name], [Type]) VALUES (N'JV', 5, N'Generate JV', N'EANEXT')
INSERT [dbo].[mtStepMaster] ([StepId], [Sequence], [Name], [Type]) VALUES (N'ExportJV', 6, N'Export JV', N'EA')
INSERT [dbo].[mtStepMaster] ([StepId], [Sequence], [Name], [Type]) VALUES (N'CLSMOC', 7, N'Close MOC', N'EO')


/****** Object:  Table [dbo].[mtPrevSecSalesReport]    Script Date: 06/23/2016 17:07:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtPrevSecSalesReport](
	[Id] [uniqueidentifier] NOT NULL,
	[CustomerCode] [nvarchar](12) NULL,
	[CustomerName] [nvarchar](250) NULL,
	[OutletCategoryMaster] [nvarchar](100) NULL,
	[BasepackCode] [nvarchar](12) NULL,
	[BasepackName] [nvarchar](250) NULL,
	[PMHBrandCode] [nvarchar](6) NULL,
	[PMHBrandName] [nvarchar](250) NULL,
	[SalesSubCat] [nvarchar](250) NULL,
	[PriceList] [nvarchar](6) NULL,
	[HulOutletCode] [nvarchar](50) NULL,
	[HulOutletCodeName] [nvarchar](250) NULL,
	[BranchCode] [nvarchar](5) NULL,
	[BranchName] [nvarchar](50) NULL,
	[MOC] [nvarchar](8) NULL,
	[OutletSecChannel] [nvarchar](50) NULL,
	[ClusterCode] [nvarchar](5) NULL,
	[ClusterName] [nvarchar](100) NULL,
	[OutletTier] [nvarchar](50) NULL,
	[TotalSalesValue] [decimal](18, 2) NULL,
	[SalesReturnValue] [decimal](18, 2) NULL,
	[NetSalesValue] [decimal](18, 2) NULL,
	[NetSalesQty] [decimal](18, 2) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO



/****** Object:  Table [dbo].[mtPrevMOCCalculation]    Script Date: 06/18/2016 14:12:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mtPrevMOCCalculation](
	[SecSalesId] [uniqueidentifier] NOT NULL,
	[ChainName] [nvarchar](100) NULL,
	[GroupName] [nvarchar](100) NULL,
	[ColorNonColor] [nvarchar](100) NULL,
	[TaxCode] [nvarchar](4) NULL,
	[StateCode] [nvarchar](4) NULL,
	[SalesTaxRate] [decimal](5, 5) NULL,
	[GSV] [decimal](18, 2) NULL,
	[ServiceTaxRate] [decimal](18, 2) NULL,
	[ServiceTax] [decimal](18, 2) NULL,
	[AdditionalMarginRate] [decimal](18, 3) NULL,
	[AdditionalMargin] [decimal](18, 2) NULL,
	[HuggiesPackPercentage] [decimal](18, 2) NULL,
	[HuggiesPackMargin] [decimal](18, 2) NULL,
	[TOTSubCategory] [nvarchar](50) NULL,
	[OnInvoiceRate] [decimal](18, 4) NULL,
	[OffInvoiceMthlyRate] [decimal](18, 4) NULL,
	[OffInvoiceQtrlyRate] [decimal](18, 4) NULL,
	[OnInvoiceValue] [decimal](18, 2) NULL,
	[OffInvoiceMthlyValue] [decimal](18, 2) NULL,
	[OffInvoiceQtrlyValue] [decimal](18, 2) NULL,
	[OnInvoiceFinalValue] [decimal](18, 2) NULL,
	[OffInvoiceMthlyFinalValue] [decimal](18, 2) NULL,
	[OffInvoiceQtrlyFinalValue] [decimal](18, 2) NULL,
	[Cluster] [nvarchar](10) NULL,
	[FirstLetterBrand] [nvarchar](1) NULL
) ON [PRIMARY]
GO


/****** Object:  Table [dbo].[mtPrevJV]    Script Date: 06/29/2016 11:31:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mtPrevJV](
	[Id] [uniqueidentifier] NOT NULL,
	[MOC] [nvarchar](8) NULL,
	[GLAccount] [nvarchar](15) NOT NULL,
	[Amount] [decimal](18, 1) NULL,
	[BranchCode] [nvarchar](5) NULL,
	[InternalOrder] [nvarchar](15) NULL,
	[GLItemText] [nvarchar](200) NULL,
	[PMHBrandCode] [nvarchar](6) NULL,
	[DistrChannel] [nvarchar](2) NULL,
	[ProfitCenter] [nvarchar](5) NULL,
	[COPACustomer] [nvarchar](10) NULL,
	[Type] [nvarchar](5) NULL,
 CONSTRAINT [PK_mtPrevJV] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO





/****** Object:  StoredProcedure [dbo].[Dashboard_CloseMOC]    Script Date: 06/28/2016 14:38:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Dashboard_CloseMOC]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Dashboard_CloseMOC]
GO


/****** Object:  StoredProcedure [dbo].[Dashboard_CloseMOC]    Script Date: 07/22/2016 11:43:51 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Dashboard_CloseMOC]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Dashboard_CloseMOC]
GO



/****** Object:  StoredProcedure [dbo].[Dashboard_CloseMOC]    Script Date: 07/22/2016 11:43:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Dashboard_CloseMOC]
      @mocMonthId int,@mocYear int,@updatedAt datetime,@updatedBy varchar(100)
AS

BEGIN

      SET NOCOUNT ON;
 BEGIN TRY
 
      BEGIN TRANSACTION
      DECLARE @moc varchar(10);  
DECLARE @mocNumber decimal(18,4)
SET @moc = CONVERT(varchar(10), @mocMonthId);  
SET @moc += '.';
SET @moc += CONVERT(varchar(10), @mocYear); 
SET @mocNumber=cast(@moc as decimal(18,4))
      
      UPDATE mtMOCStatus
	  SET Status='Close',UpdatedAt=@updatedAt,UpdatedBy=@updatedBy
	  WHERE MonthId=@mocMonthId AND [Year]=@mocYear;
	  
	  INSERT INTO mtPrevJV(Id, MOC, GLAccount, Amount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, [Type])
  SELECT Id, MOC, GLAccount, Amount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, [Type]
  FROM mtJV where MOC=@mocNumber

  DELETE FROM mtJV where MOC=@mocNumber
  
  INSERT INTO dbo.mtPrevProvision (SecSalesId, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, 
                      HulOutletCodeName, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, ChainName, 
                      GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, ServiceTax, AdditionalMarginRate, AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, 
                      TOTSubCategory, OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, OffInvoiceQtrlyValue, OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, 
                      OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand
)
  SELECT SecSalesId, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, 
                      HulOutletCodeName, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, ChainName, 
                      GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, ServiceTax, AdditionalMarginRate, AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, 
                      TOTSubCategory, OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, OffInvoiceQtrlyValue, OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, 
                      OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand

  FROM dbo.mtMOCCalculation a inner join dbo.mtSecSalesReport b on  a.SecSalesId=b.Id where b.MOC=@mocNumber
  
  DELETE FROM mtMOCCalculation
  DELETE FROM mtSecSalesReport where MOC=@mocNumber
  
	  COMMIT TRAN

 END TRY
    
 BEGIN CATCH
 ROLLBACK TRAN
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
                --ROLLBACK
 END CATCH;

END



GO





/****** Object:  Table [dbo].[mtPrevProvision]    Script Date: 06/25/2016 12:24:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mtPrevProvision](
	[SecSalesId] [uniqueidentifier] NOT NULL,
	[CustomerCode] [nvarchar](12) NULL,
	[CustomerName] [nvarchar](250) NULL,
	[OutletCategoryMaster] [nvarchar](100) NULL,
	[BasepackCode] [nvarchar](12) NULL,
	[BasepackName] [nvarchar](250) NULL,
	[PMHBrandCode] [nvarchar](6) NULL,
	[PMHBrandName] [nvarchar](250) NULL,
	[SalesSubCat] [nvarchar](250) NULL,
	[PriceList] [nvarchar](6) NULL,
	[HulOutletCode] [nvarchar](50) NULL,
	[HulOutletCodeName] [nvarchar](250) NULL,
	[BranchCode] [nvarchar](5) NULL,
	[BranchName] [nvarchar](50) NULL,
	[MOC] [decimal](18, 4) NULL,
	[OutletSecChannel] [nvarchar](50) NULL,
	[ClusterCode] [nvarchar](5) NULL,
	[ClusterName] [nvarchar](100) NULL,
	[OutletTier] [nvarchar](50) NULL,
	[TotalSalesValue] [decimal](18, 2) NULL,
	[SalesReturnValue] [decimal](18, 2) NULL,
	[NetSalesValue] [decimal](18, 2) NULL,
	[NetSalesQty] [decimal](18, 2) NULL,
	[ChainName] [nvarchar](100) NULL,
	[GroupName] [nvarchar](100) NULL,
	[ColorNonColor] [nvarchar](100) NULL,
	[TaxCode] [nvarchar](4) NULL,
	[StateCode] [nvarchar](4) NULL,
	[SalesTaxRate] [decimal](5, 5) NULL,
	[GSV] [decimal](18, 2) NULL,
	[ServiceTaxRate] [decimal](18, 2) NULL,
	[ServiceTax] [decimal](18, 2) NULL,
	[AdditionalMarginRate] [decimal](18, 3) NULL,
	[AdditionalMargin] [decimal](18, 2) NULL,
	[HuggiesPackPercentage] [decimal](18, 2) NULL,
	[HuggiesPackMargin] [decimal](18, 2) NULL,
	[TOTSubCategory] [nvarchar](50) NULL,
	[OnInvoiceRate] [decimal](18, 4) NULL,
	[OffInvoiceMthlyRate] [decimal](18, 4) NULL,
	[OffInvoiceQtrlyRate] [decimal](18, 4) NULL,
	[OnInvoiceValue] [decimal](18, 2) NULL,
	[OffInvoiceMthlyValue] [decimal](18, 2) NULL,
	[OffInvoiceQtrlyValue] [decimal](18, 2) NULL,
	[OnInvoiceFinalValue] [decimal](18, 2) NULL,
	[OffInvoiceMthlyFinalValue] [decimal](18, 2) NULL,
	[OffInvoiceQtrlyFinalValue] [decimal](18, 2) NULL,
	[Cluster] [nvarchar](10) NULL,
	[FirstLetterBrand] [nvarchar](1) NULL,
 CONSTRAINT [PK_PrevProvision] PRIMARY KEY CLUSTERED 
(
	[SecSalesId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_TotalSalesValue]  DEFAULT ((0)) FOR [TotalSalesValue]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_SalesReturnValue]  DEFAULT ((0)) FOR [SalesReturnValue]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_NetSalesValue]  DEFAULT ((0)) FOR [NetSalesValue]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_NetSalesQty]  DEFAULT ((0)) FOR [NetSalesQty]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_SalesTaxRate]  DEFAULT ((0)) FOR [SalesTaxRate]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_GSV]  DEFAULT ((0)) FOR [GSV]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_ServiceTaxRate]  DEFAULT ((0)) FOR [ServiceTaxRate]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_ServiceTax]  DEFAULT ((0)) FOR [ServiceTax]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_AdditionalMarginRate]  DEFAULT ((0)) FOR [AdditionalMarginRate]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_AdditionalMargin]  DEFAULT ((0)) FOR [AdditionalMargin]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_HuggiesPackPercentage]  DEFAULT ((0)) FOR [HuggiesPackPercentage]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_HuggiesPackMargin]  DEFAULT ((0)) FOR [HuggiesPackMargin]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_OnInvoiceRate]  DEFAULT ((0)) FOR [OnInvoiceRate]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_OffInvoiceMthlyRate]  DEFAULT ((0)) FOR [OffInvoiceMthlyRate]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_OffInvoiceQtrlyRate]  DEFAULT ((0)) FOR [OffInvoiceQtrlyRate]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_OnInvoiceValue]  DEFAULT ((0)) FOR [OnInvoiceValue]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_OffInvoiceMthlyValue]  DEFAULT ((0)) FOR [OffInvoiceMthlyValue]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_OffInvoiceQtrlyValue]  DEFAULT ((0)) FOR [OffInvoiceQtrlyValue]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_OnInvoiceFinalValue]  DEFAULT ((0)) FOR [OnInvoiceFinalValue]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_OffInvoiceMthlyFinalValue]  DEFAULT ((0)) FOR [OffInvoiceMthlyFinalValue]
GO

ALTER TABLE [dbo].[mtPrevProvision] ADD  CONSTRAINT [DF_PrevProvision_OffInvoiceQtrlyFinalValue]  DEFAULT ((0)) FOR [OffInvoiceQtrlyFinalValue]
GO

/****** Object:  StoredProcedure [dbo].[Dashboard_ReopenMOC]    Script Date: 07/22/2016 11:45:40 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Dashboard_ReopenMOC]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Dashboard_ReopenMOC]
GO

/****** Object:  StoredProcedure [dbo].[Dashboard_ReopenMOC]    Script Date: 07/22/2016 11:45:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






CREATE PROCEDURE [dbo].[Dashboard_ReopenMOC]
      @mocMonthId int,@mocYear int,@updatedAt datetime,@updatedBy varchar(300)
AS

BEGIN
 
      SET NOCOUNT ON;
 BEGIN TRY
 
      BEGIN TRANSACTION
      
      DECLARE @moc varchar(10);  
DECLARE @mocNumber decimal(18,4)
SET @moc = CONVERT(varchar(10), @mocMonthId);  
SET @moc += '.';
SET @moc += CONVERT(varchar(10), @mocYear); 
SET @mocNumber=cast(@moc as decimal(18,4))
      
      UPDATE mtMOCStatus
	  SET Status='Open',UpdatedAt=@updatedAt,UpdatedBy=@updatedBy
	  WHERE MonthId=@mocMonthId AND [Year]=@mocYear AND [Status]='Close';
	  
	  INSERT INTO mtJV (Id, MOC, GLAccount, Amount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, [Type])
                SELECT Id, MOC, GLAccount, Amount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, [Type]
  FROM mtPrevJV where MOC=@mocNumber

  DELETE FROM mtPrevJV where MOC=@mocNumber
  
  INSERT INTO mtMOCCalculation (SecSalesId, ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, ServiceTax, AdditionalMarginRate, AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory, OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, OffInvoiceQtrlyValue, OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand)
						 SELECT SecSalesId, ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, ServiceTax, AdditionalMarginRate, AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory, OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, OffInvoiceQtrlyValue, OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand
  FROM mtPrevProvision where MOC=@mocNumber
  
 INSERT INTO mtSecSalesReport (Id, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, HulOutletCodeName, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, Operation)
						 SELECT SecSalesId, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, HulOutletCodeName, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, @updatedAt, @updatedBy, null, null, 'I'
  FROM mtPrevProvision where MOC=@mocNumber
  
  DELETE FROM mtPrevProvision where MOC=@mocNumber
  
	  COMMIT TRAN
	  


 END TRY
    
 BEGIN CATCH
 ROLLBACK TRAN
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
                --ROLLBACK
 END CATCH;

END

GO





