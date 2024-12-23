
/****** Object:  Table [dbo].[mtToTProvisionTrend]    Script Date: 07/23/2016 12:02:26 ******/
IF not EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtToTProvisionTrend]') AND type in (N'U'))
BEGIN


CREATE TABLE [dbo].[mtToTProvisionTrend](
	[MtMonth] [nvarchar](10) NULL,
	[MtYear] [nvarchar](10) NULL,
	[MOC] [decimal](18, 4) NULL,
	[SubCategory] [nvarchar](250) NULL,
	[NetSalesTUR] [decimal](18, 4) NULL,
	[ToTProvision] [decimal](18, 4) NULL,
	[ToTPercentage] [decimal](18, 4) NULL
) ON [PRIMARY]

END



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







