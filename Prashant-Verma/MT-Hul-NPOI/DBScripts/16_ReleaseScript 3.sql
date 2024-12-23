delete from  mtAuditTrailMasterData where Entity='MOCStatus'


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


/****** Object:  StoredProcedure [dbo].[sp_GetMonthlyToTProvisionTrend]    Script Date: 08/10/2016 11:05:35 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetMonthlyToTProvisionTrend]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_GetMonthlyToTProvisionTrend]
GO



/****** Object:  StoredProcedure [dbo].[sp_GetMonthlyToTProvisionTrend]    Script Date: 08/10/2016 11:05:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[sp_GetMonthlyToTProvisionTrend]
	@MocYEAR int,
	@MocMonthId int
as 
begin


SELECT [MonthName]+' '+Convert(nvarchar,[MocYEAR])as UniqueMonthName ,cast((SUM(NetSalesTUR)/10000000)as  decimal(16,3))  as NetSalesTUR, cast(((SUM(ToTProvision)/10000000) )as  decimal(16,3)) as ToTProvision,cast((CASE WHEN SUM(NetSalesTUR)=0 then 0 else(SUM(ToTProvision)/SUM( NetSalesTUR)*100)end) as  decimal(16,3)) as ToTPercentage 
from mtToTProvisionTrend where ([MocYEAR]*100 + MonthId) between ((@MocYEAR-1)*100+1) and (@MocYEAR*100+@MocMonthId)  
group by  [MonthName], MocYear, MonthId order by MocYear, MonthId


END



GO




/****** Object:  StoredProcedure [dbo].[sp_GetCategoryWiseToTProvisionTrend]    Script Date: 08/10/2016 11:08:40 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetCategoryWiseToTProvisionTrend]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_GetCategoryWiseToTProvisionTrend]
GO


/****** Object:  StoredProcedure [dbo].[sp_GetCategoryWiseToTProvisionTrend]    Script Date: 08/10/2016 11:08:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[sp_GetCategoryWiseToTProvisionTrend]
	@MocYEAR int,
	@MocMonthId int
as 
begin


SELECT [MonthName]+' '+Convert(nvarchar,[MocYEAR])[MonthName] ,SubCategory,cast((NetSalesTUR/10000000)as  decimal(16,3))  as NetSalesTUR, cast((ToTProvision/10000000)as  decimal(16,3))  as ToTProvision,ToTPercentage
from mtToTProvisionTrend where SubCategory<>'ALL' AND ([MocYEAR]*100 + MonthId) between ((@MocYEAR-1)*100+@MocMonthId) and (@MocYEAR*100+@MocMonthId)  
 order by MocYear, MonthId


END




GO




/****** Object:  StoredProcedure [dbo].[sp_UploadDataCategoryWiseToTProvisionTrend]    Script Date: 08/10/2016 12:33:12 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_UploadDataCategoryWiseToTProvisionTrend]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_UploadDataCategoryWiseToTProvisionTrend]
GO



/****** Object:  StoredProcedure [dbo].[sp_UploadDataCategoryWiseToTProvisionTrend]    Script Date: 08/10/2016 12:33:12 ******/
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
sum(OnInvoiceFinalValue+OffInvoiceMthlyFinalValue+OffInvoiceQtrlyFinalValue) as ToTProvision from mtMOCCalculation a join mtSecSalesReport b
on a.SecSalesId=b.Id  where MOC=CONVERT(varchar(10),@MocMonthId)+'.'+CONVERT(varchar(10),@MocYEAR) --and sum(NetSalesValue) > 0 --and sum(OnInvoiceFinalValue+OffInvoiceMthlyFinalValue+OffInvoiceQtrlyFinalValue) > 0 
group by MOC ,TOTSubCategory)

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



/****** Object:  View [dbo].[vwCustomerwiseReport_PrevMOC]    Script Date: 08/10/2016 16:33:27 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vwCustomerwiseReport_PrevMOC]'))
DROP VIEW [dbo].[vwCustomerwiseReport_PrevMOC]
GO


/****** Object:  View [dbo].[vwCustomerwiseReport_PrevMOC]    Script Date: 08/10/2016 16:33:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [dbo].[vwCustomerwiseReport_PrevMOC]

AS
SELECT    
convert(varchar(50),m.quarter + substring(convert(varchar(50),moc),CHARINDEX('.',convert(varchar(50),moc))+3,2)) QTR ,convert(varchar(50),m.month + substring(convert(varchar(50),moc),CHARINDEX('.',convert(varchar(50),moc))+3,2)) Month ,  a.SecSalesId,
 CustomerCode, CustomerName,  BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode,
  
                       BranchCode,  MOC,  ClusterCode,  OutletTier,   NetSalesValue,  
                        ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV,
                         ServiceTaxRate, ServiceTax, AdditionalMarginRate, 
                      AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory,
                       OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, 
                       OffInvoiceMthlyValue, 
                      OffInvoiceQtrlyValue, OnInvoiceFinalValue,
                       OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand
FROM         mtPrevProvision a  left outer join mtmonth m on
 convert(int,substring(convert(varchar(50),a.moc),0,CHARINDEX('.',convert(varchar(50),a.moc)))) = m.Id





GO




/****** Object:  View [dbo].[vwCustomerwiseReport_CurrentMOC]    Script Date: 08/10/2016 16:33:20 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vwCustomerwiseReport_CurrentMOC]'))
DROP VIEW [dbo].[vwCustomerwiseReport_CurrentMOC]
GO



/****** Object:  View [dbo].[vwCustomerwiseReport_CurrentMOC]    Script Date: 08/10/2016 16:33:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[vwCustomerwiseReport_CurrentMOC]

AS
SELECT    
convert(varchar(50),m.quarter + substring(convert(varchar(50),moc),CHARINDEX('.',convert(varchar(50),moc))+3,2)) QTR ,convert(varchar(50),m.month + substring(convert(varchar(50),moc),CHARINDEX('.',convert(varchar(50),moc))+3,2)) Month ,  a.Id,
 CustomerCode, CustomerName,  BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode,
  
                       BranchCode,  MOC,  ClusterCode,  OutletTier,   NetSalesValue,  
                        ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV,
                         ServiceTaxRate, ServiceTax, AdditionalMarginRate, 
                      AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory,
                       OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, 
                       OffInvoiceMthlyValue, 
                      OffInvoiceQtrlyValue, OnInvoiceFinalValue,
                       OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand
FROM         vwCalculatedProvision a  left outer join mtmonth m on
 convert(int,substring(convert(varchar(50),a.moc),0,CHARINDEX('.',convert(varchar(50),a.moc)))) = m.Id




GO


delete from [mtToTProvisionTrend] where (([MocYEAR]*100) + MonthId) < (2016 * 100) + 6

/****** Object:  Table [dbo].[mtToTProvisionTrend]    Script Date: 08/10/2016 17:08:31 ******/
INSERT [dbo].[mtToTProvisionTrend] ([MonthName], [MocYear], [MonthId], [SubCategory], [NetSalesTUR], [ToTProvision], [ToTPercentage]) VALUES (N'OCT', 2015, 10, N'ALL', CAST(1926744457.2001 AS Decimal(18, 4)), CAST(112409267.4207 AS Decimal(18, 4)), CAST(5.8300 AS Decimal(18, 4)))
INSERT [dbo].[mtToTProvisionTrend] ([MonthName], [MocYear], [MonthId], [SubCategory], [NetSalesTUR], [ToTProvision], [ToTPercentage]) VALUES (N'NOV', 2015, 11, N'ALL', CAST(2035894407.5700 AS Decimal(18, 4)), CAST(120488554.4229 AS Decimal(18, 4)), CAST(5.9200 AS Decimal(18, 4)))
INSERT [dbo].[mtToTProvisionTrend] ([MonthName], [MocYear], [MonthId], [SubCategory], [NetSalesTUR], [ToTProvision], [ToTPercentage]) VALUES (N'DEC', 2015, 12, N'ALL', CAST(2112489563.6000 AS Decimal(18, 4)), CAST(123788358.1782 AS Decimal(18, 4)), CAST(5.8600 AS Decimal(18, 4)))
INSERT [dbo].[mtToTProvisionTrend] ([MonthName], [MocYear], [MonthId], [SubCategory], [NetSalesTUR], [ToTProvision], [ToTPercentage]) VALUES (N'JAN', 2016, 1, N'ALL', CAST(2328121836.7800 AS Decimal(18, 4)), CAST(139889839.0172 AS Decimal(18, 4)), CAST(6.0100 AS Decimal(18, 4)))
INSERT [dbo].[mtToTProvisionTrend] ([MonthName], [MocYear], [MonthId], [SubCategory], [NetSalesTUR], [ToTProvision], [ToTPercentage]) VALUES (N'FEB', 2016, 2, N'ALL', CAST(1929909000.3100 AS Decimal(18, 4)), CAST(111800000.0000 AS Decimal(18, 4)), CAST(5.7900 AS Decimal(18, 4)))
INSERT [dbo].[mtToTProvisionTrend] ([MonthName], [MocYear], [MonthId], [SubCategory], [NetSalesTUR], [ToTProvision], [ToTPercentage]) VALUES (N'MAR', 2016, 3, N'ALL', CAST(1872083656.7701 AS Decimal(18, 4)), CAST(111478054.0809 AS Decimal(18, 4)), CAST(5.9500 AS Decimal(18, 4)))
INSERT [dbo].[mtToTProvisionTrend] ([MonthName], [MocYear], [MonthId], [SubCategory], [NetSalesTUR], [ToTProvision], [ToTPercentage]) VALUES (N'APR', 2016, 4, N'ALL', CAST(1990810856.4700 AS Decimal(18, 4)), CAST(118800000.0000 AS Decimal(18, 4)), CAST(5.9700 AS Decimal(18, 4)))
INSERT [dbo].[mtToTProvisionTrend] ([MonthName], [MocYear], [MonthId], [SubCategory], [NetSalesTUR], [ToTProvision], [ToTPercentage]) VALUES (N'MAY', 2016, 5, N'ALL', CAST(2037926592.0101 AS Decimal(18, 4)), CAST(122579024.7711 AS Decimal(18, 4)), CAST(6.0100 AS Decimal(18, 4)))
INSERT [dbo].[mtToTProvisionTrend] ([MonthName], [MocYear], [MonthId], [SubCategory], [NetSalesTUR], [ToTProvision], [ToTPercentage]) VALUES (N'JUN', 2016, 6, N'ALL', CAST(2124700000.0000 AS Decimal(18, 4)), CAST(120880000.0000 AS Decimal(18, 4)), CAST(5.6900 AS Decimal(18, 4)))
--INSERT [dbo].[mtToTProvisionTrend] ([MonthName], [MocYear], [MonthId], [SubCategory], [NetSalesTUR], [ToTProvision], [ToTPercentage]) VALUES (N'JUL', 2016, 7, N'ALL', CAST(2051800866.8902 AS Decimal(18, 4)), CAST(124100000.0000 AS Decimal(18, 4)), CAST(6.0500 AS Decimal(18, 4)))
/****** Object:  Table [dbo].[mtMonth]    Script Date: 08/10/2016 17:08:31 ******/


delete from [mtMonth]

INSERT [dbo].[mtMonth] ([Id], [Month], [Quarter]) VALUES (CAST(1 AS Numeric(18, 0)), N'JAN', N'1')
INSERT [dbo].[mtMonth] ([Id], [Month], [Quarter]) VALUES (CAST(2 AS Numeric(18, 0)), N'FEB', N'1')
INSERT [dbo].[mtMonth] ([Id], [Month], [Quarter]) VALUES (CAST(3 AS Numeric(18, 0)), N'MAR', N'1')
INSERT [dbo].[mtMonth] ([Id], [Month], [Quarter]) VALUES (CAST(4 AS Numeric(18, 0)), N'APR', N'2')
INSERT [dbo].[mtMonth] ([Id], [Month], [Quarter]) VALUES (CAST(5 AS Numeric(18, 0)), N'MAY', N'2')
INSERT [dbo].[mtMonth] ([Id], [Month], [Quarter]) VALUES (CAST(6 AS Numeric(18, 0)), N'JUN', N'2')
INSERT [dbo].[mtMonth] ([Id], [Month], [Quarter]) VALUES (CAST(7 AS Numeric(18, 0)), N'JUL', N'3')
INSERT [dbo].[mtMonth] ([Id], [Month], [Quarter]) VALUES (CAST(8 AS Numeric(18, 0)), N'AUG', N'3')
INSERT [dbo].[mtMonth] ([Id], [Month], [Quarter]) VALUES (CAST(9 AS Numeric(18, 0)), N'SEP', N'3')
INSERT [dbo].[mtMonth] ([Id], [Month], [Quarter]) VALUES (CAST(10 AS Numeric(18, 0)), N'OCT', N'4')
INSERT [dbo].[mtMonth] ([Id], [Month], [Quarter]) VALUES (CAST(11 AS Numeric(18, 0)), N'NOV', N'4')
INSERT [dbo].[mtMonth] ([Id], [Month], [Quarter]) VALUES (CAST(12 AS Numeric(18, 0)), N'DEC', N'4')







/****** Object:  StoredProcedure [dbo].[sp_UploadDataCategoryWiseToTProvisionTrend]    Script Date: 08/16/2016 17:36:32 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_UploadDataCategoryWiseToTProvisionTrend]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_UploadDataCategoryWiseToTProvisionTrend]
GO


/****** Object:  StoredProcedure [dbo].[sp_UploadDataCategoryWiseToTProvisionTrend]    Script Date: 08/16/2016 17:36:32 ******/
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
select  SalesSubCat,MOC ,sum(NetSalesValue)as NetSalesValue ,
sum(OnInvoiceFinalValue+OffInvoiceMthlyFinalValue+OffInvoiceQtrlyFinalValue) as ToTProvision from mtMOCCalculation a join mtSecSalesReport b
on a.SecSalesId=b.Id  where MOC=CONVERT(varchar(10),@MocMonthId)+'.'+CONVERT(varchar(10),@MocYEAR) --and sum(NetSalesValue) > 0 --and sum(OnInvoiceFinalValue+OffInvoiceMthlyFinalValue+OffInvoiceQtrlyFinalValue) > 0 
group by MOC ,SalesSubCat)

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
	SUBSTRING(convert(nvarchar(20),MOC),len(MOC)-3,4),(SUBSTRING(convert(nvarchar(20),MOC),0,len(MOC)-4)),SalesSubCat,NetSalesValue,ToTProvision,(CASE WHEN ToTProvision <> 0 THEN cast( ToTProvision/NetSalesValue* 100 as  decimal(16,3))ELSE 0 END )
	  from AllToTProvision --where NetSalesValue > 0 and ToTProvision =0 
	
END






GO



/****** Object:  StoredProcedure [dbo].[sp_DeleteSecSalesReportInBatch]    Script Date: 08/23/2016 18:46:14 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_DeleteSecSalesReportInBatch]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_DeleteSecSalesReportInBatch]
GO


/****** Object:  StoredProcedure [dbo].[sp_DeleteSecSalesReportInBatch]    Script Date: 08/23/2016 18:46:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[sp_DeleteSecSalesReportInBatch]
	@Moc nvarchar(10)
as 

BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
      
  
Declare @allMOCCalcCount int
SET @allMOCCalcCount= (select COUNT(*)from mtMOCCalculation where SecSalesId in (select Id from mtSecSalesReport where MOC=@Moc))

While(@allMOCCalcCount!=0)
BEGIN
delete TOP(10000) from mtMOCCalculation where SecSalesId in (select Id from mtSecSalesReport where MOC=@Moc)
END	

Declare @allCount int


SET @allCount= (select COUNT(*)from mtSecSalesReport where MOC =@Moc)

While(@allCount!=0)
BEGIN
Delete TOP(10000) from mtSecSalesReport where MOC =@Moc
END


delete from mtJV where MOC=@Moc
	


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




/****** Object:  StoredProcedure [dbo].[Update_StepAfterUploadSecSalesReport]    Script Date: 08/23/2016 18:45:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_StepAfterUploadSecSalesReport]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_StepAfterUploadSecSalesReport]
GO


/****** Object:  StoredProcedure [dbo].[Update_StepAfterUploadSecSalesReport]    Script Date: 08/23/2016 18:45:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[Update_StepAfterUploadSecSalesReport]
      @mocMonthId nvarchar(2),@mocYear nvarchar(4),@stepId varchar(20),
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
      
      
UPDATE mtMOCWiseStepDetails 
SET Status='NotStarted',UpdatedBy=@user ,UpdatedAt = getdate()
WHERE MonthId=@mocMonthId AND [YEAR]=@mocYear AND StepId 
in (select StepId from mtStepMaster where Sequence > (select Sequence from mtStepMaster where StepId=@stepId))	
		

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




/****** Object:  StoredProcedure [dbo].[sp_DeleteSecSalesReportInBatch]    Script Date: 08/26/2016 19:46:14 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_DeleteSecSalesReportInBatch]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_DeleteSecSalesReportInBatch]
GO



/****** Object:  StoredProcedure [dbo].[sp_DeleteSecSalesReportInBatch]    Script Date: 08/26/2016 19:46:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[sp_DeleteSecSalesReportInBatch]
	@Moc nvarchar(10)
as 

BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
      
  
Declare @allMOCCalcCount int
SET @allMOCCalcCount= (select COUNT(*)from mtMOCCalculation where SecSalesId in (select Id from mtSecSalesReport where MOC=@Moc))

While(@allMOCCalcCount!=0)
BEGIN
delete TOP(10000) from mtMOCCalculation where SecSalesId in (select Id from mtSecSalesReport where MOC=@Moc)

SET @allMOCCalcCount= (select COUNT(*)from mtMOCCalculation where SecSalesId in (select Id from mtSecSalesReport where MOC=@Moc))

END	
-- Truncate table mtMOCCalculation

Declare @allCount int


SET @allCount= (select COUNT(*)from mtSecSalesReport where MOC =@Moc)

While(@allCount!=0)
BEGIN
Delete TOP(10000) from mtSecSalesReport where MOC =@Moc
SET @allCount= (select COUNT(*)from mtSecSalesReport where MOC =@Moc)

END

--Truncate table mtSecSalesReport

delete from mtJV where MOC=@Moc
	


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


