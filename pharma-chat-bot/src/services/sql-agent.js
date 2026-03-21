import { callAiProviderOrchestration } from './ai-provider-orchestration.js';

export const generateSQL = async (question) => {
  const prompt = `
You are a pharma data analyst.
Convert the user question into SQL using tables:
- sales(date, product, region, seasonality_factor, promotion, stockout, shock_event, units_sold, price_per_unit, revenue)
)
- inventory(date, test_id,abcd,category,region,warehouse,batch_id,current_stock,avg_daily_sales,lead_time_days,safety_stock,reorder_point,max_stock_level,expiry_date,last_sale_date,supplier_id,supplier_reliability,inward_qty,outward_qty,adjustment_qty,aging_bucket,unit_cost,total_stock_value
)
- cashflow(date,product,region,opening_cash,collections,payments,operating_cash_flow,capex,investments,investing_cash_flow,loans,dividends,financing_cash_flow,net_cash_flow,closing_cash
)

Do not join tables. Return ONLY SQL.

Question: ${question}
`;

  const res = await callAiProviderOrchestration(
    { role: 'user', content: prompt }
  );

  return res.response;
};
