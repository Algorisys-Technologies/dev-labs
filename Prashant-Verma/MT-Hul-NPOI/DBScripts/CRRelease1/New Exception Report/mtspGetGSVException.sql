/****** Object:  StoredProcedure [dbo].[mtspGetGSVException]    Script Date: 07/19/2017 17:38:20 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetGSVException]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetGSVException]
GO

/****** Object:  StoredProcedure [dbo].[mtspGetGSVException]    Script Date: 07/19/2017 17:38:20 ******/
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
--select * from vwCalculatedProvision
--where (statecode is null) or (TaxCode is null and
-- statecode not in (select statecode from mtOnInvoiceValueConfig
--  where IsNetSalesValueAppl=1))or (taxcode is null and statecode is null)
--and 
--  MOC= @moc  

select * from vwCalculatedProvision prov
where BasepackCode not in ( select BasepackCode from mtgstmaster)
and MOC= @moc  
)

SELECT * FROM  (select ROW_NUMBER()OVER (ORDER BY @sortColumnName) AS RowNumber,* from
table1) a WHERE RowNumber BETWEEN  @start AND  @recordupto
END






GO


