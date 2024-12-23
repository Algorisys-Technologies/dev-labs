/****** Object:  StoredProcedure [dbo].[mtspMoveSecSalesData]    Script Date: 07/20/2017 12:23:54 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspMoveSecSalesData]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspMoveSecSalesData]
GO

/****** Object:  StoredProcedure [dbo].[mtspMoveSecSalesData]    Script Date: 07/20/2017 12:23:54 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspMoveSecSalesData]  
--Todo MOC as input
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

 insert into  mtSecSalesReport
(Id,CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode,HulOutletCodeName, BranchCode,BranchName, MOC,OutletSecChannel, ClusterCode,ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty,IsGstApplicable)
select newid(), CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat,LTRIM(RTRIM( replace(PriceList,'-',''))), HulOutletCode,HulOutletCodeName, BranchCode,BranchName, MOC,OutletSecChannel, ClusterCode,ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty,IsGstApplicable
from mtTempSecSalesReport

Truncate table mtTempSecSalesReport

END


GO


