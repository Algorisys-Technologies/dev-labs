

/****** Object:  StoredProcedure [dbo].[mtspGetAllGSVException]    Script Date: 07/12/2016 12:31:09 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetAllGSVException]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetAllGSVException]
GO


/****** Object:  StoredProcedure [dbo].[mtspGetAllGSVException]    Script Date: 07/12/2016 12:31:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspGetAllGSVException] 
	@moc nvarchar(7)
AS
BEGIN
select CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName,
 SalesSubCat, PriceList, HulOutletCode,HulOutletCodeName, BranchCode, BranchName, MOC, OutletSecChannel, 
 ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, 
TaxCode, StateCode, SalesTaxRate, GSV
                      
                       from vwCalculatedProvision
where (statecode is null) or (TaxCode is null and
 statecode not in (select statecode from mtOnInvoiceValueConfig
  where IsNetSalesValueAppl=1))or (taxcode is null and statecode is null)
and 
  MOC= @moc  
END





GO




/****** Object:  StoredProcedure [dbo].[mtspGetAllProvChainNmGrpNmEx]    Script Date: 07/12/2016 12:31:13 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetAllProvChainNmGrpNmEx]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetAllProvChainNmGrpNmEx]
GO



/****** Object:  StoredProcedure [dbo].[mtspGetAllProvChainNmGrpNmEx]    Script Date: 07/12/2016 12:31:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[mtspGetAllProvChainNmGrpNmEx] 
	@moc nvarchar(7)
AS
BEGIN
select CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, 
SalesSubCat, PriceList, HulOutletCode, HulOutletCodeName, ChainName, 
GroupName, ColorNonColor, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier,
 TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, TaxCode, StateCode, SalesTaxRate, GSV
                      
  FROM
   vwCalculatedProvision 
   
  WHERE (ChainName  is null OR  GroupName is null OR  ColorNonColor is null)  AND 
  MOC= @moc
END

GO




/****** Object:  StoredProcedure [dbo].[mtspGetAllProvExOnTOTSubCategory]    Script Date: 07/12/2016 12:31:16 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetAllProvExOnTOTSubCategory]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetAllProvExOnTOTSubCategory]
GO

/****** Object:  StoredProcedure [dbo].[mtspGetAllProvExOnTOTSubCategory]    Script Date: 07/12/2016 12:31:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[mtspGetAllProvExOnTOTSubCategory] 
	@moc nvarchar(7)
AS
BEGIN
select 
CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, 
SalesSubCat, PriceList,TOTSubCategory, HulOutletCode, HulOutletCodeName, v.ChainName, 
v.GroupName, v.ColorNonColor, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier,
 TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, TaxCode, StateCode, SalesTaxRate, GSV
                      

  FROM
   vwCalculatedProvision v
   JOIN
   (Select distinct ChainName, groupName from mtSubCategoryTOTMaster) subcatRate ON v.ChainName = subcatRate.ChainName and v.GroupName = subcatRate.GroupName      
 
  WHERE  
  v.MOC= @moc and v.TOTSubCategory is null 
END
GO



/****** Object:  StoredProcedure [dbo].[mtspGetGSVException]    Script Date: 07/12/2016 12:31:20 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetGSVException]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetGSVException]
GO


/****** Object:  StoredProcedure [dbo].[mtspGetGSVException]    Script Date: 07/12/2016 12:31:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspGetGSVException] 
	@moc nvarchar(7),
	@start int,
	@recordupto int,
	@sortColumnName nvarchar(200)
AS
BEGIN
with table1 as(
select * from vwCalculatedProvision
where (statecode is null) or (TaxCode is null and
 statecode not in (select statecode from mtOnInvoiceValueConfig
  where IsNetSalesValueAppl=1))or (taxcode is null and statecode is null)
and 
  MOC= @moc  )

SELECT * FROM  (select ROW_NUMBER()OVER (ORDER BY @sortColumnName) AS RowNumber,* from
table1) a WHERE RowNumber BETWEEN  @start AND  @recordupto
END





GO




/****** Object:  StoredProcedure [dbo].[mtspGetProvisionExceptionOnTOTSubCategory]    Script Date: 07/12/2016 12:31:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetProvisionExceptionOnTOTSubCategory]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetProvisionExceptionOnTOTSubCategory]
GO


/****** Object:  StoredProcedure [dbo].[mtspGetProvisionExceptionOnTOTSubCategory]    Script Date: 07/12/2016 12:31:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspGetProvisionExceptionOnTOTSubCategory] 
	@moc nvarchar(7),
	@start int,
	@recordupto int,
	@sortColumnName nvarchar(200)
AS
BEGIN
with TOTSubCategory as(
select PriceList,PMHBrandCode,PMHBrandName,TOTSubCategory ,SalesSubCat
  FROM
   vwCalculatedProvision v
   JOIN
   (Select distinct ChainName, groupName from mtSubCategoryTOTMaster) subcatRate ON v.ChainName = subcatRate.ChainName and v.GroupName = subcatRate.GroupName      
  -- JOIN
   --mtBrandWiseTOTSubCategoryMapping om ON om.PMHBrandCode=v.PMHBrandCode and om.SalesSubCat= v.SalesSubCat 
  -- and  om.PriceList= v.PriceList 
   
  WHERE  
  v.MOC= @moc and v.TOTSubCategory is null group by PriceList,PMHBrandCode,PMHBrandName,TOTSubCategory,SalesSubCat )

SELECT *  FROM  (select ROW_NUMBER()OVER (ORDER BY @sortColumnName) AS RowNumber,* from
TOTSubCategory) a WHERE RowNumber BETWEEN  @start AND  @recordupto 
END




GO




/****** Object:  StoredProcedure [dbo].[mtspGetProvisionExOnChainNmGrpNm]    Script Date: 07/12/2016 12:31:29 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetProvisionExOnChainNmGrpNm]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetProvisionExOnChainNmGrpNm]
GO


/****** Object:  StoredProcedure [dbo].[mtspGetProvisionExOnChainNmGrpNm]    Script Date: 07/12/2016 12:31:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspGetProvisionExOnChainNmGrpNm] 
	@moc nvarchar(7),
	@start int,
	@recordupto int,
	@sortColumnName nvarchar(200)
AS
BEGIN
with TOTSubCategory as(
select * FROM vwCalculatedProvision 
  
WHERE ChainName  is null OR  GroupName is null OR  ColorNonColor is null AND  MOC= @moc )

SELECT * FROM  (select ROW_NUMBER()OVER (ORDER BY @sortColumnName) AS RowNumber,* from
TOTSubCategory) a WHERE RowNumber BETWEEN  @start AND  @recordupto
END





GO



/****** Object:  StoredProcedure [dbo].[mtspGetRowCountProvExOnTOTSubCategory]    Script Date: 07/12/2016 12:31:56 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetRowCountProvExOnTOTSubCategory]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetRowCountProvExOnTOTSubCategory]
GO


/****** Object:  StoredProcedure [dbo].[mtspGetRowCountProvExOnTOTSubCategory]    Script Date: 07/12/2016 12:31:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspGetRowCountProvExOnTOTSubCategory] 
	@moc nvarchar(7)
AS
BEGIN

with recCount as (
 select COUNT(*) as RecCount
  FROM
   vwCalculatedProvision v
   JOIN
   (Select distinct ChainName, groupName from mtSubCategoryTOTMaster) subcatRate ON v.ChainName = subcatRate.ChainName and v.GroupName = subcatRate.GroupName      
   --JOIN
   --mtBrandWiseTOTSubCategoryMapping om ON om.PMHBrandCode=v.PMHBrandCode and om.SalesSubCat= v.SalesSubCat 
   --and  om.PriceList= v.PriceList 
   
  WHERE  
  v.MOC= @moc and v.TOTSubCategory is null group by PriceList,PMHBrandCode,PMHBrandName,TOTSubCategory,SalesSubCat)
  
  select COUNT(*) from RecCount
END





GO



/****** Object:  StoredProcedure [dbo].[mtspGetRowCountProExOnOutLetCode]    Script Date: 07/12/2016 12:31:52 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetRowCountProExOnOutLetCode]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetRowCountProExOnOutLetCode]
GO


/****** Object:  StoredProcedure [dbo].[mtspGetRowCountProExOnOutLetCode]    Script Date: 07/12/2016 12:31:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspGetRowCountProExOnOutLetCode] 
	@moc nvarchar(7)
AS
BEGIN
select COUNT(distinct(HulOutletCode)) from vwCalculatedProvision
where ChainName  is null OR  GroupName is null OR  ColorNonColor is null
and 
  MOC= @moc 
END






GO




/****** Object:  StoredProcedure [dbo].[mtspGetRowCountProExChainNmGrpNm]    Script Date: 07/12/2016 12:31:45 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetRowCountProExChainNmGrpNm]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetRowCountProExChainNmGrpNm]
GO



/****** Object:  StoredProcedure [dbo].[mtspGetRowCountProExChainNmGrpNm]    Script Date: 07/12/2016 12:31:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspGetRowCountProExChainNmGrpNm] 
	@moc nvarchar(7)
AS
BEGIN
select COUNT(*) from vwCalculatedProvision
where ChainName  is null OR  GroupName is null OR  ColorNonColor is null
and 
  MOC= @moc 
END






GO




/****** Object:  StoredProcedure [dbo].[mtspGetRowCountGSVException]    Script Date: 07/12/2016 12:31:41 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetRowCountGSVException]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetRowCountGSVException]
GO

/****** Object:  StoredProcedure [dbo].[mtspGetRowCountGSVException]    Script Date: 07/12/2016 12:31:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspGetRowCountGSVException] 
	@moc nvarchar(7)
AS
BEGIN
select COUNT(*) from vwCalculatedProvision
where (statecode is null) or (TaxCode is null and
 statecode not in (select statecode from mtOnInvoiceValueConfig
  where IsNetSalesValueAppl=1))or (taxcode is null and statecode is null)
and 
  MOC= @moc 
END





GO




/****** Object:  StoredProcedure [dbo].[mtspGetProvisionExOnHulOutletCode]    Script Date: 07/12/2016 12:31:34 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetProvisionExOnHulOutletCode]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetProvisionExOnHulOutletCode]
GO


/****** Object:  StoredProcedure [dbo].[mtspGetProvisionExOnHulOutletCode]    Script Date: 07/12/2016 12:31:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspGetProvisionExOnHulOutletCode] 
	@moc nvarchar(7),
	@start int,
	@recordupto int,
	@sortColumnName nvarchar(200)
AS
BEGIN
with TOTSubCategory as(
select * FROM vwCalculatedProvision 
  
WHERE ChainName  is null OR  GroupName is null OR  ColorNonColor is null AND  MOC= @moc )

SELECT distinct(HulOutletCode)as HulOutletCode, HulOutletCodeName, ChainName,GroupName,ColorNonColor FROM  (select ROW_NUMBER()OVER (ORDER BY @sortColumnName) AS RowNumber,* from
TOTSubCategory) a WHERE RowNumber BETWEEN  @start AND  @recordupto
group by HulOutletCode,HulOutletCodeName,ChainName,GroupName,ColorNonColor 
END





GO




/****** Object:  StoredProcedure [dbo].[sp_GetAllProvisionExceptionOnTOTSubCategory]    Script Date: 07/20/2016 12:05:14 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetAllProvisionExceptionOnTOTSubCategory]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_GetAllProvisionExceptionOnTOTSubCategory]
GO


/****** Object:  StoredProcedure [dbo].[sp_GetAllProvisionExceptionOnTOTSubCategory]    Script Date: 07/20/2016 12:05:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetAllProvisionExceptionOnTOTSubCategory] 
	@moc nvarchar(7)
AS
BEGIN
with TOTSubCategory as(
select PriceList as [Price List],PMHBrandCode as [PMH Brand Code], PMHBrandName as [PMH Brand Name],SalesSubCat as [Sales Sub Category],TOTSubCategory  as [TOT Sub Category]
  FROM
   vwCalculatedProvision v
   JOIN
   (Select distinct ChainName, groupName from mtSubCategoryTOTMaster) subcatRate ON v.ChainName = subcatRate.ChainName and v.GroupName = subcatRate.GroupName      
  
  WHERE  
  v.MOC= @moc and v.TOTSubCategory is null group by PriceList,PMHBrandCode,PMHBrandName,TOTSubCategory,SalesSubCat )

SELECT *  FROM  TOTSubCategory order by [Price List],[PMH Brand Code]
END





GO



/****** Object:  StoredProcedure [dbo].[sp_GetAllProvisionExOnHulOutletCode]    Script Date: 07/20/2016 12:05:11 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetAllProvisionExOnHulOutletCode]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_GetAllProvisionExOnHulOutletCode]
GO

/****** Object:  StoredProcedure [dbo].[sp_GetAllProvisionExOnHulOutletCode]    Script Date: 07/20/2016 12:05:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetAllProvisionExOnHulOutletCode] 
	@moc nvarchar(7)
AS
BEGIN
with TOTSubCategory as(
select * FROM vwCalculatedProvision 
  
WHERE ChainName  is null OR  GroupName is null OR  ColorNonColor is null AND  MOC= @moc )

SELECT distinct(HulOutletCode)as [Hul Outlet Code], HulOutletCodeName as [Hul Outlet Code Name], ChainName as [Chain Name],GroupName as[Group Name],ColorNonColor as  [Color NonColor] FROM 
TOTSubCategory 
group by HulOutletCode,HulOutletCodeName,ChainName,GroupName,ColorNonColor order by [Hul Outlet Code]
END






GO


