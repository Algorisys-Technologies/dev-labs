export const detectDeadStock = (inventory) => {
  return inventory.filter(i => i.last_sold_days > 90 && i.stock_qty > 0);
};

export const topProfitableProducts = (sales) => {
  const map = {};

  sales.forEach(s => {
    const profit = s.revenue - s.cost;
    map[s.product] = (map[s.product] || 0) + profit;
  });

  return Object.entries(map)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);
};