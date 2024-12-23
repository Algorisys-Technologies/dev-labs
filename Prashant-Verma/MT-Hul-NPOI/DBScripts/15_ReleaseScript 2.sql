
ALTER TABLE mtOnInvoiceValueConfig
ALTER COLUMN StateCode [nvarchar](255)


----------------------------
----------------------------

/****** Object:  Table [dbo].[mtToTProvisionTrend]    Script Date: 08/01/2016 12:27:21 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtToTProvisionTrend]') AND type in (N'U'))
DROP TABLE [dbo].[mtToTProvisionTrend]
GO

/****** Object:  Table [dbo].[mtToTProvisionTrend]    Script Date: 08/01/2016 12:27:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mtToTProvisionTrend](
	[MonthName] [nvarchar](10) NULL,
	[MocYear] [int] NULL,
	[MonthId] [int] NULL,
	[SubCategory] [nvarchar](250) NULL,
	[NetSalesTUR] [decimal](18, 4) NULL,
	[ToTProvision] [decimal](18, 4) NULL,
	[ToTPercentage] [decimal](18, 4) NULL
) ON [PRIMARY]

GO


/****** Object:  StoredProcedure [dbo].[sp_GetZeroProvisionOutlet]    Script Date: 07/21/2016 18:50:40 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetZeroProvisionOutlet]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_GetZeroProvisionOutlet]
GO


/****** Object:  StoredProcedure [dbo].[sp_GetZeroProvisionOutlet]    Script Date: 07/21/2016 18:50:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[sp_GetZeroProvisionOutlet]
	@MOC nvarchar(7),
	@start int,
	@recordupto int,
	@sortColumnName nvarchar(200),
	@search nvarchar(300)
as 
begin
Declare @newsearch nvarchar(300)
set @newsearch=''
if(@search!='')
BEGIN
set @newsearch=' AND '+ @search
END

EXECUTE ( 'with AllToTProvision as(
select  OutletCategoryMaster,HulOutletCode,HulOutletCodeName,MOC,sum(NetSalesValue)as NetSalesValue ,
sum(OnInvoiceFinalValue+OffInvoiceMthlyFinalValue+OffInvoiceQtrlyFinalValue) as ToTProvision,chainName ,groupname from mtMOCCalculation a join mtSecSalesReport b
on a.SecSalesId=b.Id  where MOC='+ @MOC + 'group by OutletCategoryMaster,HulOutletCode,HulOutletCodeName,MOC,ChainName ,GroupName )

SELECT * FROM  (select ROW_NUMBER()OVER ( '+@sortColumnName +') AS RowNumber,* from
AllToTProvision where NetSalesValue > 0 and
 ToTProvision =0 '+@newsearch+') a WHERE RowNumber BETWEEN  '+@start+' AND  '+@recordupto)

END
GO




/****** Object:  StoredProcedure [dbo].[sp_GetZeroProvisionOutletRowCount]    Script Date: 07/21/2016 18:50:36 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetZeroProvisionOutletRowCount]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_GetZeroProvisionOutletRowCount]
GO



/****** Object:  StoredProcedure [dbo].[sp_GetZeroProvisionOutletRowCount]    Script Date: 07/21/2016 18:50:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[sp_GetZeroProvisionOutletRowCount]
	@MOC nvarchar(7)
as 
begin

with AllToTProvision as(
select  OutletCategoryMaster,HulOutletCode,HulOutletCodeName,MOC,sum(NetSalesValue)as NetSalesValue ,
sum(OnInvoiceFinalValue+OffInvoiceMthlyFinalValue+OffInvoiceQtrlyFinalValue) as ToTProvision,chainName ,groupname from mtMOCCalculation a join mtSecSalesReport b
on a.SecSalesId=b.Id  where MOC=@MOC --and sum(NetSalesValue) > 0 --and sum(OnInvoiceFinalValue+OffInvoiceMthlyFinalValue+OffInvoiceQtrlyFinalValue) > 0 
group by OutletCategoryMaster,HulOutletCode,HulOutletCodeName,MOC,ChainName ,GroupName )


SELECT COUNT(*)  from AllToTProvision where NetSalesValue > 0 and ToTProvision =0 
--Insert into mtToTProvisionTrend ()

END

GO





/****** Object:  StoredProcedure [dbo].[sp_GetAllZeroProvisionOutlet]    Script Date: 07/22/2016 12:13:56 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetAllZeroProvisionOutlet]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_GetAllZeroProvisionOutlet]
GO


/****** Object:  StoredProcedure [dbo].[sp_GetAllZeroProvisionOutlet]    Script Date: 07/22/2016 12:13:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[sp_GetAllZeroProvisionOutlet]
	@MOC nvarchar(7)
as 
begin

with AllToTProvision as(
select  OutletCategoryMaster,HulOutletCode,HulOutletCodeName,MOC,sum(NetSalesValue)as NetSalesValue ,
sum(OnInvoiceFinalValue+OffInvoiceMthlyFinalValue+OffInvoiceQtrlyFinalValue) as ToTProvision,chainName ,groupname from mtMOCCalculation a join mtSecSalesReport b
on a.SecSalesId=b.Id  where MOC=@MOC --and sum(NetSalesValue) > 0 --and sum(OnInvoiceFinalValue+OffInvoiceMthlyFinalValue+OffInvoiceQtrlyFinalValue) > 0 
group by OutletCategoryMaster,HulOutletCode,HulOutletCodeName,MOC,ChainName ,GroupName )


SELECT *  from AllToTProvision where NetSalesValue > 0 and ToTProvision =0 
--Insert into mtToTProvisionTrend ()

END

GO







-------------Start Bootsrap data updated----------------------------------------


IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF__mtPriceLi__Creat__671F4F74]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[mtPriceListMaster] DROP CONSTRAINT [DF__mtPriceLi__Creat__671F4F74]
END

GO

/****** Object:  Table [dbo].[mtPriceListMaster]    Script Date: 07/19/2016 18:23:37 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtPriceListMaster]') AND type in (N'U'))
DROP TABLE [dbo].[mtPriceListMaster]
GO


/****** Object:  Table [dbo].[mtPriceListMaster]    Script Date: 07/19/2016 18:23:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtPriceListMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PriceList] [nvarchar](50) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[mtPriceListMaster] ADD  DEFAULT (getdate()) FOR [CreatedAt]
GO




IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_mtOnInvoiceValueConfig_IsNetSalesValueAppl]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[mtOnInvoiceValueConfig] DROP CONSTRAINT [DF_mtOnInvoiceValueConfig_IsNetSalesValueAppl]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF__mtOnInvoi__Creat__681373AD]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[mtOnInvoiceValueConfig] DROP CONSTRAINT [DF__mtOnInvoi__Creat__681373AD]
END

GO


/****** Object:  Table [dbo].[mtOnInvoiceValueConfig]    Script Date: 07/19/2016 18:23:24 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtOnInvoiceValueConfig]') AND type in (N'U'))
DROP TABLE [dbo].[mtOnInvoiceValueConfig]
GO



/****** Object:  Table [dbo].[mtOnInvoiceValueConfig]    Script Date: 07/19/2016 18:23:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtOnInvoiceValueConfig](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[StateCode] [nvarchar](4) NULL,
	[IsNetSalesValueAppl] [bit] NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NULL,
 CONSTRAINT [PK_mtOnInvoiceValueConfig] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[mtOnInvoiceValueConfig] ADD  CONSTRAINT [DF_mtOnInvoiceValueConfig_IsNetSalesValueAppl]  DEFAULT ((0)) FOR [IsNetSalesValueAppl]
GO

ALTER TABLE [dbo].[mtOnInvoiceValueConfig] ADD  CONSTRAINT [DF__mtOnInvoi__Creat__681373AD]  DEFAULT (getdate()) FOR [CreatedAt]
GO




IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF__mtGLMaste__Creat__690797E6]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[mtGLMaster] DROP CONSTRAINT [DF__mtGLMaste__Creat__690797E6]
END

GO

/****** Object:  Table [dbo].[mtGLMaster]    Script Date: 07/19/2016 18:23:12 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtGLMaster]') AND type in (N'U'))
DROP TABLE [dbo].[mtGLMaster]
GO


/****** Object:  Table [dbo].[mtGLMaster]    Script Date: 07/19/2016 18:23:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtGLMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[DbCr] [nvarchar](2) NULL,
	[GLAccount] [nvarchar](15) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NULL,
 CONSTRAINT [PK_mtGLMaster] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[mtGLMaster] ADD  CONSTRAINT [DF__mtGLMaste__Creat__690797E6]  DEFAULT (getdate()) FOR [CreatedAt]
GO



/****** Object:  Table [dbo].[mtChainNameMaster]    Script Date: 07/19/2016 18:22:54 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtChainNameMaster]') AND type in (N'U'))
DROP TABLE [dbo].[mtChainNameMaster]
GO


/****** Object:  Table [dbo].[mtChainNameMaster]    Script Date: 07/19/2016 18:22:54 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtChainNameMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ChainName] [nvarchar](100) NULL,
	[IsHuggiesAppl] [bit] NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO



/****** Object:  StoredProcedure [dbo].[Delete_ChainName]    Script Date: 07/19/2016 18:57:31 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_ChainName]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_ChainName]
GO



/****** Object:  StoredProcedure [dbo].[Delete_ChainName]    Script Date: 07/19/2016 18:57:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Create procedure [dbo].[Delete_ChainName]
@updatedBy varchar(200),
@chainName varchar(200)
as 
begin
SET NOCOUNT ON;
begin try
BEGIN TRAN
declare @huggies as nvarchar(255)
declare @id as int

set @huggies=(select IsHuggiesAppl from mtChainNameMaster where ChainName=@chainName)
set @id=(select Id from mtChainNameMaster where ChainName=@chainName)


delete from mtChainNameMaster where ChainName=@chainName
insert into mtAuditTrailMasterData values(NEWID(),'mtChianNameMaster','id',@id,'ChainName'+' : '+@chainName+'^IsHuggiesAppl'+' : '+@huggies,'D',getdate(),@updatedBy)


COMMIT
end try

  
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




/****** Object:  StoredProcedure [dbo].[Delete_OnInVoiceConfig]    Script Date: 07/19/2016 18:57:43 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_OnInVoiceConfig]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_OnInVoiceConfig]
GO



/****** Object:  StoredProcedure [dbo].[Delete_OnInVoiceConfig]    Script Date: 07/19/2016 18:57:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[Delete_OnInVoiceConfig]
@updatedBy varchar(200),
@stateCode varchar(200)
as 
begin
SET NOCOUNT ON;
begin try
BEGIN TRAN

declare @id as int
declare @netsale as nvarchar(10)


set @id=(select Id from mtOnInvoiceValueConfig where StateCode=@stateCode)
set @netsale=(select IsNetSalesValueAppl from mtOnInvoiceValueConfig where StateCode=@stateCode)


delete from mtOnInvoiceValueConfig where StateCode=@stateCode
insert into mtAuditTrailMasterData values(NEWID(),'mtOnIvoiceValueConfig','id',@id,'StateCode'+' : '+@stateCode+'^IsNetSalesValueAppl'+' : '+@netsale,'D',getdate(),@updatedBy)


COMMIT
end try

  
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




/****** Object:  StoredProcedure [dbo].[Delete_PriceList]    Script Date: 07/19/2016 18:57:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_PriceList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_PriceList]
GO



/****** Object:  StoredProcedure [dbo].[Delete_PriceList]    Script Date: 07/19/2016 18:57:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Create procedure [dbo].[Delete_PriceList] 
@updatedBy varchar(200),
@priceList varchar(200)
as 
begin
SET NOCOUNT ON;
begin try
BEGIN TRAN

declare @id as int


set @id=(select Id from mtPriceListMaster where PriceList=@priceList)


delete from mtPriceListMaster where PriceList=@priceList
insert into mtAuditTrailMasterData values(NEWID(),'mtPriceListMaster','id',@id,'PriceList'+' : '+@priceList,'D',getdate(),@updatedBy)


COMMIT
end try

  
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




/****** Object:  StoredProcedure [dbo].[Update_ChainNameMaster]    Script Date: 07/19/2016 18:57:57 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_ChainNameMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_ChainNameMaster]
GO


/****** Object:  StoredProcedure [dbo].[Update_ChainNameMaster]    Script Date: 07/19/2016 18:57:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Update_ChainNameMaster]
@updatedBy varchar(200),
@newChainName varchar(200),
@oldChainName varchar(200),
@isHuggiesAppl varchar(10)
as 
begin
SET NOCOUNT ON;
begin try
BEGIN TRAN

declare @id as nvarchar(200)
declare @oldHuggiesAppl as nvarchar(200)

set @id=(select Id from mtChainNameMaster where ChainName=@oldChainName)
set @OldHuggiesAppl=(select case when IsHuggiesAppl=1 then 'true' else 'false' end as IsHuggiesAppl from mtChainNameMaster where ChainName=@oldChainName)

update mtChainNameMaster set ChainName=@newChainName,IsHuggiesAppl=@isHuggiesAppl,Operation='U',UpdatedAt=GETDATE(),UpdatedBy=@updatedBy where ChainName=@oldChainName
insert into mtAuditTrailMasterData values(NEWID(),'mtChianNameMaster','id',@id,'ChainName'+' : '+@oldChainName+' | '+@newChainName+'^IsHuggiesAppl'+' : '+@oldHuggiesAppl+' | '+@isHuggiesAppl,'U',getdate(),@updatedBy)


COMMIT
end try

  
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



select *from mtChainNameMaster

GO



/****** Object:  StoredProcedure [dbo].[Update_OnInVoiceConfig]    Script Date: 07/19/2016 18:58:14 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_OnInVoiceConfig]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_OnInVoiceConfig]
GO


/****** Object:  StoredProcedure [dbo].[Update_OnInVoiceConfig]    Script Date: 07/19/2016 18:58:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Update_OnInVoiceConfig]
@updatedBy varchar(200),
@newStateCode varchar(200),
@oldStateCode varchar(200),
@isNetSaleAppl varchar(10)
as 
begin
SET NOCOUNT ON;
begin try
BEGIN TRAN

declare @id as nvarchar(200)
declare @oldNetSaleAppl as nvarchar(200)

set @id=(select Id from mtOnInvoiceValueConfig where StateCode=@oldStateCode)
set @oldNetSaleAppl=(select case when IsNetSalesValueAppl=1 then 'true' else 'false' end as IsNetSalesValueAppl from mtOnInvoiceValueConfig where StateCode=@oldStateCode)

update mtOnInvoiceValueConfig set StateCode=@newStateCode,IsNetSalesValueAppl=@isNetSaleAppl,Operation='U',UpdatedAt=GETDATE(),UpdatedBy=@updatedBy where StateCode=@oldStateCode
insert into mtAuditTrailMasterData values(NEWID(),'mtOnInvoiceValueConfig','id',@id,'StateCode'+' : '+@oldStateCode+' | '+@newStateCode+'^IsNetSalesValueAppl'+' : '+@oldNetSaleAppl+' | '+@isNetSaleAppl,'U',getdate(),@updatedBy)


COMMIT
end try

  
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



select *from mtChainNameMaster

GO




/****** Object:  StoredProcedure [dbo].[Update_PriceListMaster]    Script Date: 07/19/2016 18:58:09 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_PriceListMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_PriceListMaster]
GO



/****** Object:  StoredProcedure [dbo].[Update_PriceListMaster]    Script Date: 07/19/2016 18:58:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Update_PriceListMaster]
@updatedBy varchar(200),
@newPriceList varchar(200),
@oldPriceList varchar(200)

as 
begin
SET NOCOUNT ON;
begin try
BEGIN TRAN

declare @id as nvarchar(200)


set @id=(select Id from mtPriceListMaster where PriceList=@oldPriceList)


update mtPriceListMaster set PriceList=@newPriceList,Operation='U',UpdatedAt=GETDATE(),UpdatedBy=@updatedBy where PriceList=@oldPriceList
insert into mtAuditTrailMasterData values(NEWID(),'mtPriceListMaster','id',@id,'Price List'+' : '+@newPriceList+' | '+@OldPriceList,'U',getdate(),@updatedBy)


COMMIT
end try

  
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




/****** Object:  StoredProcedure [dbo].[Update_GLMaster]    Script Date: 07/19/2016 18:59:02 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_GLMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_GLMaster]
GO



/****** Object:  StoredProcedure [dbo].[Update_GLMaster]    Script Date: 07/19/2016 18:59:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Update_GLMaster]
@updatedBy varchar(200),
@newRecord varchar(200),
@oldRecord varchar(200)
as 
begin
SET NOCOUNT ON;
begin try
BEGIN TRAN
declare @dbCr as nvarchar(255)
declare @id as nvarchar(200)
set @dbCr=(select Dbcr from mtGLMaster where GLAccount=@oldRecord)
set @id=(select Id from mtGLMaster where GLAccount=@oldRecord)

update mtGLMaster set GLAccount=@newRecord,Operation='U',UpdatedAt=GETDATE(),UpdatedBy=@updatedBy where GLAccount=@oldRecord
insert into mtAuditTrailMasterData values(NEWID(),'mtGLMaster','id',@id,'Dbcr'+' : '+@dbCr+'^GLAccount'+' : '+@oldRecord+' | '+@newRecord,'U',getdate(),@updatedBy)


COMMIT
end try

  
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







/****** Object:  Table [dbo].[mtPriceListMaster]    Script Date: 07/19/2016 18:27:01 ******/
SET IDENTITY_INSERT [dbo].[mtPriceListMaster] ON
INSERT [dbo].[mtPriceListMaster] ([Id], [PriceList], [CreatedBy], [CreatedAt], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (1, N'PP', N'Admin', CAST(0x0000A6480126DC2C AS DateTime), NULL, NULL, N'I')
INSERT [dbo].[mtPriceListMaster] ([Id], [PriceList], [CreatedBy], [CreatedAt], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (2, N'DETS', N'Admin', CAST(0x0000A6480126DC2C AS DateTime), NULL, NULL, N'I')
INSERT [dbo].[mtPriceListMaster] ([Id], [PriceList], [CreatedBy], [CreatedAt], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (3, N'HUL3', N'Admin', CAST(0x0000A6480126DC2C AS DateTime), NULL, NULL, N'I')
INSERT [dbo].[mtPriceListMaster] ([Id], [PriceList], [CreatedBy], [CreatedAt], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (4, N'FnB', N'Admin', CAST(0x0000A6480126DC2C AS DateTime), NULL, NULL, N'I')
SET IDENTITY_INSERT [dbo].[mtPriceListMaster] OFF
/****** Object:  Table [dbo].[mtOnInvoiceValueConfig]    Script Date: 07/19/2016 18:27:01 ******/
SET IDENTITY_INSERT [dbo].[mtOnInvoiceValueConfig] ON
INSERT [dbo].[mtOnInvoiceValueConfig] ([Id], [StateCode], [IsNetSalesValueAppl], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (1, N'PNJ', 1, CAST(0x0000A6480126DC36 AS DateTime), N'Admin', NULL, NULL, N'I')
SET IDENTITY_INSERT [dbo].[mtOnInvoiceValueConfig] OFF
/****** Object:  Table [dbo].[mtGLMaster]    Script Date: 07/19/2016 18:27:01 ******/
SET IDENTITY_INSERT [dbo].[mtGLMaster] ON
INSERT [dbo].[mtGLMaster] ([Id], [DbCr], [GLAccount], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (1, N'Dr', N'0002120114', CAST(0x0000A64801271DDF AS DateTime), N'Admin', NULL, NULL, N'I')
INSERT [dbo].[mtGLMaster] ([Id], [DbCr], [GLAccount], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (2, N'Cr', N'0001442413', CAST(0x0000A64801271DDF AS DateTime), N'Admin', NULL, NULL, N'I')
SET IDENTITY_INSERT [dbo].[mtGLMaster] OFF
/****** Object:  Table [dbo].[mtChainNameMaster]    Script Date: 07/19/2016 18:27:01 ******/
SET IDENTITY_INSERT [dbo].[mtChainNameMaster] ON
INSERT [dbo].[mtChainNameMaster] ([Id], [ChainName], [IsHuggiesAppl], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (1, N'COOPS', 0, CAST(0x0000A58000000000 AS DateTime), N'Admin', NULL, NULL, N'I')
INSERT [dbo].[mtChainNameMaster] ([Id], [ChainName], [IsHuggiesAppl], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (2, N'Direct Customers', 0, CAST(0x0000A58000000000 AS DateTime), N'Admin', NULL, NULL, N'I')
INSERT [dbo].[mtChainNameMaster] ([Id], [ChainName], [IsHuggiesAppl], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (3, N'RC', 0, CAST(0x0000A58000000000 AS DateTime), N'Admin', NULL, NULL, N'I')
INSERT [dbo].[mtChainNameMaster] ([Id], [ChainName], [IsHuggiesAppl], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (4, N'LULU', 0, CAST(0x0000A58000000000 AS DateTime), N'Admin', NULL, NULL, N'I')
INSERT [dbo].[mtChainNameMaster] ([Id], [ChainName], [IsHuggiesAppl], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (5, N'E-Commerce', 0, CAST(0x0000A58000000000 AS DateTime), N'Admin', NULL, NULL, N'I')
INSERT [dbo].[mtChainNameMaster] ([Id], [ChainName], [IsHuggiesAppl], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (6, N'Pharma Chain', 1, CAST(0x0000A58000000000 AS DateTime), N'Admin', NULL, NULL, N'I')
INSERT [dbo].[mtChainNameMaster] ([Id], [ChainName], [IsHuggiesAppl], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (7, N'NMT', 0, CAST(0x0000A58000000000 AS DateTime), N'Admin', NULL, NULL, N'I')
SET IDENTITY_INSERT [dbo].[mtChainNameMaster] OFF


delete from [dbo].[mtServiceTaxRateMaster]
/****** Object:  Table [dbo].[mtServiceTaxRateMaster]    Script Date: 06/17/2016 10:57:51 ******/
SET IDENTITY_INSERT [dbo].[mtServiceTaxRateMaster] ON
INSERT [dbo].[mtServiceTaxRateMaster] ([Id], [ChainName], [GroupName], [Rate], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (5, N'Direct Customers', N'FOOD BAZAR', CAST(0.15 AS Decimal(5, 2)), CAST(0x0000A61F0117435A AS DateTime), N'Admin', CAST(0x0000A61F0129F4DD AS DateTime), N'Admin', N'U')
INSERT [dbo].[mtServiceTaxRateMaster] ([Id], [ChainName], [GroupName], [Rate], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy], [Operation]) VALUES (6, N'Direct Customers', N'EASY DAY', CAST(0.15 AS Decimal(5, 2)), CAST(0x0000A61F0117435A AS DateTime), N'Admin', CAST(0x0000A61F0129F4DD AS DateTime), N'Admin', N'U')
SET IDENTITY_INSERT [dbo].[mtServiceTaxRateMaster] OFF

update mtMasterDetails set Status='Done' where DetailedStep='SERVICETAX'



delete from [dbo].[mtPageRightMaster]

GO
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'CUSTGRP', N'Customer Group Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'SKU', N'SKU Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'SALESTAXRATE', N'Sales Tax Rate Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'OUTLETMASTER', N'Outlet Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'ADDMARGIN', N'Add Margin Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'SERVICETAX', N'Service Tax Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'HUGGIESBAEPACK', N'Huggies BasePack Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'CLUSTERRSCODE', N'Cluster RS Code Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'TIERBASEDTOT', N'Tier Based TOT Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'SUBCATMAPPING', N'Sub Category Mapping Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'SUBCATBASEDTOT', N'Sub Category TOT Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'UPSEC', N'Secondary Sales Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'GSV', N'Calculate GSV', N'execute')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'PVSION', N'Calculate Provision', N'execute')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'JV', N'Generate JV', N'execute')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'ExportJV', N'Export JV', N'extract')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'CLSMOC', N'CloseMOC', N'execute')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'CHAINNAME', N'Chain Name Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'OnInvoiceVal', N'OnInvoice Volume Config Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'PriceList', N'Price List Master', N'read/write')
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'GL', N'GL Master', N'read/write')

---------------------End Bootstarp data------------------



------------start TOT provision Trand Report------------------

/****Selcondary sales Delete data****/


/****** Object:  StoredProcedure [dbo].[sp_DeleteSecSalesReportInBatch]    Script Date: 07/28/2016 14:15:40 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_DeleteSecSalesReportInBatch]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_DeleteSecSalesReportInBatch]
GO


/****** Object:  StoredProcedure [dbo].[sp_DeleteSecSalesReportInBatch]    Script Date: 07/28/2016 14:15:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[sp_DeleteSecSalesReportInBatch]
	@Moc nvarchar(10)
as 
begin
Declare @allCount int
SET @allCount= (select COUNT(*)from mtSecSalesReport where MOC =@Moc)


While(@allCount!=0)
BEGIN
Delete TOP(10000) from mtSecSalesReport where MOC =@Moc
END


END



GO



/**tot Provision Trend***/


SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtToTProvisionTrend]') AND type in (N'U'))
Begin

CREATE TABLE [dbo].[mtToTProvisionTrend](
 [MonthName] [nvarchar](10) NULL,
 [MocYear] [int] NULL,
 [MonthId] [int] NULL,
 [SubCategory] [nvarchar](250) NULL,
 [NetSalesTUR] [decimal](18, 4) NULL,
 [ToTProvision] [decimal](18, 4) NULL,
 [ToTPercentage] [decimal](18, 4) NULL
) ON [PRIMARY]

END


GO



/****** Object:  StoredProcedure [dbo].[sp_GetCategoryWiseToTProvisionTrend]    Script Date: 07/28/2016 10:56:39 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetCategoryWiseToTProvisionTrend]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_GetCategoryWiseToTProvisionTrend]
GO


/****** Object:  StoredProcedure [dbo].[sp_GetCategoryWiseToTProvisionTrend]    Script Date: 07/28/2016 10:56:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[sp_GetCategoryWiseToTProvisionTrend]
	@MocYEAR int,
	@MocMonthId int
as 
begin


SELECT [MonthName]+' '+Convert(nvarchar,[MocYEAR])[MonthName] ,SubCategory,cast((NetSalesTUR/100000)as  decimal(16,3))  as NetSalesTUR, cast((ToTProvision/100000)as  decimal(16,3))  as ToTProvision,ToTPercentage
from mtToTProvisionTrend where ([MocYEAR]*100 + MonthId) between ((@MocYEAR-1)*100+@MocMonthId) and (@MocYEAR*100+@MocMonthId)  
 order by MocYear, MonthId


END



GO




/****** Object:  StoredProcedure [dbo].[sp_GetMonthlyToTProvisionTrend]    Script Date: 07/28/2016 10:56:33 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetMonthlyToTProvisionTrend]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_GetMonthlyToTProvisionTrend]
GO



/****** Object:  StoredProcedure [dbo].[sp_GetMonthlyToTProvisionTrend]    Script Date: 07/28/2016 10:56:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[sp_GetMonthlyToTProvisionTrend]
	@MocYEAR int,
	@MocMonthId int
as 
begin


SELECT [MonthName]+' '+Convert(nvarchar,[MocYEAR])as UniqueMonthName ,cast((SUM(NetSalesTUR)/100000)as  decimal(16,3))  as NetSalesTUR, cast(((SUM(ToTProvision)/100000) )as  decimal(16,3)) as ToTProvision,cast((CASE WHEN SUM(NetSalesTUR)=0 then 0 else(SUM(ToTProvision)/SUM( NetSalesTUR)*100)end) as  decimal(16,3)) as ToTPercentage 
from mtToTProvisionTrend where ([MocYEAR]*100 + MonthId) between ((@MocYEAR-1)*100+1) and (@MocYEAR*100+@MocMonthId)  
group by  [MonthName], MocYear, MonthId order by MocYear, MonthId


END


GO



/****** Object:  StoredProcedure [dbo].[sp_UploadDataCategoryWiseToTProvisionTrend]    Script Date: 08/01/2016 14:24:44 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_UploadDataCategoryWiseToTProvisionTrend]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_UploadDataCategoryWiseToTProvisionTrend]
GO


/****** Object:  StoredProcedure [dbo].[sp_UploadDataCategoryWiseToTProvisionTrend]    Script Date: 08/01/2016 14:24:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[sp_UploadDataCategoryWiseToTProvisionTrend]
	@MocYEAR int,
	@MocMonthId int
as 
begin

DELETE FROM mtToTProvisionTrend where  MocYear=@MocYEAR AND	MonthId=@MocMonthId;


with AllToTProvision as(
--select  OutletCategoryMaster,TOTSubCategory,HulOutletCode,HulOutletCodeName,MOC,sum(NetSalesValue)as NetSalesValue ,
select  TOTSubCategory,MOC ,sum(NetSalesValue)as NetSalesValue ,
sum(OnInvoiceFinalValue+OffInvoiceMthlyFinalValue+OffInvoiceQtrlyFinalValue) as ToTProvision,chainName ,groupname from mtMOCCalculation a join mtSecSalesReport b
on a.SecSalesId=b.Id  where MOC=CONVERT(varchar(10),@MocMonthId)+'.'+CONVERT(varchar(10),@MocYEAR) --and sum(NetSalesValue) > 0 --and sum(OnInvoiceFinalValue+OffInvoiceMthlyFinalValue+OffInvoiceQtrlyFinalValue) > 0 
group by MOC ,TOTSubCategory,ChainName ,GroupName)

INSERT INTO mtToTProvisionTrend (
		MonthName,
		MocYear,
		MonthId,
		SubCategory,
		NetSalesTUR,
		ToTProvision,
		ToTPercentage
	) 
	SELECT 
	SUBSTRING('JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC ', ((SUBSTRING(convert(nvarchar(20),MOC),0,len(MOC)-4)) * 4) - 3, 3),
	SUBSTRING(convert(nvarchar(20),MOC),len(MOC)-3,4),(SUBSTRING(convert(nvarchar(20),MOC),0,len(MOC)-4)),TOTSubCategory,NetSalesValue,ToTProvision,(CASE WHEN ToTProvision <> 0 THEN cast( ToTProvision/NetSalesValue* 100 as  decimal(16,3))ELSE 0 END )
	  from AllToTProvision --where NetSalesValue > 0 and ToTProvision =0 
	
END




GO




------------END TOT Provision Trend Report---------------

---------------start updates in open MOC close MOC----------------




/****** Object:  StoredProcedure [dbo].[mtCreate_newMOCDetails_FirstTime]    Script Date: 08/02/2016 17:11:30 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtCreate_newMOCDetails_FirstTime]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtCreate_newMOCDetails_FirstTime]
GO

/****** Object:  StoredProcedure [dbo].[mtCreate_newMOCDetails_FirstTime]    Script Date: 08/02/2016 17:11:30 ******/
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
      
				INSERT INTO mtAuditTrailMasterData 
				SELECT newid() Id, 'MOCStatus' Entity,'MOC' KeyName,
				convert(varchar, @mocMonthId)+'.'+convert(varchar, @mocYear) as [Key], 
				'Status : open'  as Data,'U' as Operation ,
				getdate() as UpdatedAt,@createdBy as UpdatedBy 
	 
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



/****** Object:  StoredProcedure [dbo].[mtCreate_newMOCDetails]    Script Date: 08/02/2016 17:11:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtCreate_newMOCDetails]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtCreate_newMOCDetails]
GO



/****** Object:  StoredProcedure [dbo].[mtCreate_newMOCDetails]    Script Date: 08/02/2016 17:11:26 ******/
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
      
				INSERT INTO mtAuditTrailMasterData 
				SELECT newid() Id, 'MOCStatus' Entity,'MOC' KeyName,
				convert(varchar, @mocMonthId)+'.'+convert(varchar, @mocYear) as [Key], 
				'Status : open'  as Data,'U' as Operation ,
				getdate() as UpdatedAt,@createdBy as UpdatedBy 
	 
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



/****** Object:  StoredProcedure [dbo].[Dashboard_ReopenMOC]    Script Date: 08/02/2016 17:11:13 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Dashboard_ReopenMOC]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Dashboard_ReopenMOC]
GO


/****** Object:  StoredProcedure [dbo].[Dashboard_ReopenMOC]    Script Date: 08/02/2016 17:11:13 ******/
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
      
      				INSERT INTO mtAuditTrailMasterData 
				SELECT newid() Id, 'MOCStatus' Entity,'MOC' KeyName,
				convert(varchar, @mocMonthId)+'.'+convert(varchar, @mocYear) as [Key], 
				'Status : close|open'  as Data,'U' as Operation ,
				getdate() as UpdatedAt,@updatedBy as UpdatedBy 
	
      
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



/****** Object:  StoredProcedure [dbo].[Dashboard_CloseMOC]    Script Date: 08/02/2016 17:11:09 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Dashboard_CloseMOC]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Dashboard_CloseMOC]
GO



/****** Object:  StoredProcedure [dbo].[Dashboard_CloseMOC]    Script Date: 08/02/2016 17:11:09 ******/
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
      
				INSERT INTO mtAuditTrailMasterData 
				SELECT newid() Id, 'MOCStatus' Entity,'MOC' KeyName,
				convert(varchar, @mocMonthId)+'.'+convert(varchar, @mocYear) as [Key], 
				'Status : close'  as Data,'U' as Operation ,
				getdate() as UpdatedAt,@updatedBy as UpdatedBy 
	 
      
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


---- end updates in open MOC close MOC-------------------