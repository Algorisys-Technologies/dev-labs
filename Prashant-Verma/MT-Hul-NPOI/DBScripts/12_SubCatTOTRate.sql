/****** Object:  StoredProcedure [dbo].[mtspGetSubCatTOTRateData]    Script Date: 07/14/2016 18:50:40 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetSubCatTOTRateData]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetSubCatTOTRateData]
GO

/****** Object:  StoredProcedure [dbo].[mtspGetSubCatTOTRateData]    Script Date: 07/14/2016 18:50:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO








-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspGetSubCatTOTRateData] 
	@rateColumn nvarchar(50)
AS
BEGIN
DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
DECLARE @var VARCHAR(MAX) = '';

SELECT @var += quotename(x.Totsubcategory) + ','
FROM 
(
  SELECT DISTINCT (Totsubcategory) as Totsubcategory
  FROM mtBrandWiseTOTSubCategoryMapping
) AS x;

set @var = SUBSTRING(@var,1,len(@var)-1)
--SELECT @var;

SET @DynamicPivotQuery = 
  N'SELECT ChainName [Chain Name], GroupName [Group Name], Branch, ' + @var + 
  'FROM 
(SELECT ChainName, GroupName, Branch, '+@rateColumn+' ,Totsubcategory
FROM mtSubCategoryTOTMaster) p
PIVOT
(
sum ('+@rateColumn+')
FOR Totsubcategory IN(' + @var + ' )
) AS pvt 
order by ChainName,GroupName,Branch'
EXEC sp_executesql @DynamicPivotQuery
END







GO


