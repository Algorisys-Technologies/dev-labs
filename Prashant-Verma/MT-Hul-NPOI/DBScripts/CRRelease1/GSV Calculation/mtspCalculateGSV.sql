/****** Object:  StoredProcedure [dbo].[mtspCalculateGSV]    Script Date: 07/21/2017 17:24:50 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspCalculateGSV]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspCalculateGSV]
GO

/****** Object:  StoredProcedure [dbo].[mtspCalculateGSV]    Script Date: 07/21/2017 17:24:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspCalculateGSV] 
	@moc nvarchar(7)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if(select count(*) FROM mtMOCCalculation mocCal, mtSecSalesReport sec 
		where mocCal.SecSalesId=sec.Id and sec.moc = @moc) = 0
	begin
		print 'insert in mtmoccalculation'
		INSERT into mtMOCCalculation(SecSalesId,IsGstApplicable)
		SELECT id,IsGstApplicable from mtSecSalesReport where moc= @moc
	end

    --Update Chain Name, Group Name and Color
		--UPDATE
		--mocCal
		--SET
		--	ChainName = om.ChainName,
		--	GroupName = om.GroupName,
		--	ColorNonColor = om.ColorNoncolor
		--FROM
		--	mtMOCCalculation mocCal
		--	JOIN
		--	mtSecSalesReport sec ON 
		--	mocCal.SecSalesId=sec.Id 
		--	JOIN
		--	mtOutletMaster om ON 
		--om.HulOutletCode=sec.HulOutletCode
		--WHERE
		--sec.MOC= @moc


		----Update TaxCode
		--UPDATE
		--	mocCal
		--SET
		--	TaxCode = om.TaxCode
		--FROM
		--	mtMOCCalculation mocCal
		--	JOIN
		--	mtSecSalesReport sec ON 

		--mocCal.SecSalesId=sec.Id 
		--	JOIN
		--	mtSkuMaster om ON 

		--om.BasepackCode=sec.BasepackCode
		--WHERE
		--sec.MOC= @moc

		----Update StateCode
		--UPDATE
		--	mocCal
		--SET
		--	StateCode = om.StateCode
		--FROM
		--	mtMOCCalculation mocCal
		--	JOIN
		--	mtSecSalesReport sec ON 

		--mocCal.SecSalesId=sec.Id 
		--	JOIN
		--	mtCustomerGroupMaster om ON 

		--om.CustomerCode=sec.CustomerCode
		--WHERE
		--sec.MOC= @moc

		----Update Sales Tax Rate, Sales Tax
		--UPDATE
		--	mocCal
		--SET
		--	SalesTaxRate = om.SalesTaxRate,
		--	GSV = round((sec.NetSalesValue/(1+om.SalesTaxRate)),3)
		--FROM
		--	mtMOCCalculation mocCal
		--	JOIN
		--	mtSecSalesReport sec ON 

		--mocCal.SecSalesId=sec.Id 
		--	JOIN
		--	mtSalesTaxMaster om ON 

		--om.StateCode=mocCal.StateCode and 

		--om.TaxCode = mocCal.TaxCode
		--WHERE
		--sec.MOC= @moc
		
		
		---------------GST Ralated Changes start				
		--Update TaxCode
		UPDATE
			mocCal
		SET
			TaxCode = om.TaxCode
		FROM
			mtMOCCalculation mocCal
			JOIN
			mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 
			JOIN mtSkuMaster om ON  om.BasepackCode=sec.BasepackCode
		WHERE
		sec.MOC= @moc and sec.IsGstApplicable =0

		--Update StateCode
		UPDATE
			mocCal
		SET
			StateCode = om.StateCode
		FROM
			mtMOCCalculation mocCal
			JOIN
			mtSecSalesReport sec ON 

		mocCal.SecSalesId=sec.Id 
			JOIN
			mtCustomerGroupMaster om ON 

		om.CustomerCode=sec.CustomerCode
		WHERE
		sec.MOC= @moc and sec.IsGstApplicable =0

		--Update Sales Tax Rate, Sales Tax
		UPDATE
			mocCal
		SET
			SalesTaxRate = om.SalesTaxRate,
			GSV = round((sec.NetSalesValue/(1+om.SalesTaxRate)),3)
		FROM
			mtMOCCalculation mocCal
			JOIN
			mtSecSalesReport sec ON 

		mocCal.SecSalesId=sec.Id 
			JOIN
			mtSalesTaxMaster om ON  om.StateCode=mocCal.StateCode and om.TaxCode = mocCal.TaxCode
		WHERE
		sec.MOC= @moc and sec.IsGstApplicable =0
		
		--Update GST Rate, GST Tax
		UPDATE
			mocCal
		SET
			SalesTaxRate = om.gstRate,
			GSV = round((sec.NetSalesValue/(1+om.gstRate)),3)
		FROM
			mtMOCCalculation mocCal
			JOIN mtSecSalesReport sec ON mocCal.SecSalesId=sec.Id 
			JOIN
			(select basepackcode, MIN(gstrate) gstRate from mtgstmaster
			group by basepackcode) om 
			ON 	om.basepackcode=sec.basepackcode 
			WHERE
			sec.MOC= @moc and sec.IsGstApplicable = 1

		
		
			--Update first letter of Brand
			UPDATE
			mocCal
			SET
				FirstLetterBrand = SUBSTRING(sec.PMHBrandCode,1,1)
			FROM
				mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 							
			WHERE
			sec.MOC=  @moc
			
			
			

END




GO


