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


