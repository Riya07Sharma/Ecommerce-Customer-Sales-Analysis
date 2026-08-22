{
  "cells": [
    {
      "cell_type": "markdown",
      "metadata": {},
      "source": [
        "# E-Commerce Customer & Sales Analysis\n",
        "End-to-end EDA using Customers, Orders, Products, Order_Items and Payments."
      ]
    },
    {
      "cell_type": "code",
      "execution_count": null,
      "metadata": {},
      "outputs": [],
      "source": [
        "import pandas as pd\n",
        "import matplotlib.pyplot as plt\n",
        "customers = pd.read_csv('../data/customers.csv')\n",
        "orders = pd.read_csv('../data/orders.csv', parse_dates=['order_date'])\n",
        "products = pd.read_csv('../data/products.csv')\n",
        "items = pd.read_csv('../data/order_items.csv')\n",
        "payments = pd.read_csv('../data/payments.csv')\n"
      ]
    },
    {
      "cell_type": "markdown",
      "metadata": {},
      "source": [
        "## Data quality checks"
      ]
    },
    {
      "cell_type": "code",
      "execution_count": null,
      "metadata": {},
      "outputs": [],
      "source": [
        "for name, df in {'customers':customers,'orders':orders,'products':products,'items':items,'payments':payments}.items():\n",
        "    print(name, 'shape=', df.shape, 'missing=', int(df.isna().sum().sum()), 'duplicates=', int(df.duplicated().sum()))\n"
      ]
    },
    {
      "cell_type": "markdown",
      "metadata": {},
      "source": [
        "## KPIs"
      ]
    },
    {
      "cell_type": "code",
      "execution_count": null,
      "metadata": {},
      "outputs": [],
      "source": [
        "delivered = orders[orders['status'].eq('Delivered')].copy()\n",
        "print('Total orders:', len(delivered))\n",
        "print('Total revenue:', round(delivered['order_total'].sum(),2))\n",
        "print('AOV:', round(delivered['order_total'].mean(),2))\n"
      ]
    },
    {
      "cell_type": "markdown",
      "metadata": {},
      "source": [
        "## Monthly revenue"
      ]
    },
    {
      "cell_type": "code",
      "execution_count": null,
      "metadata": {},
      "outputs": [],
      "source": [
        "monthly = delivered.assign(month=delivered['order_date'].dt.to_period('M').astype(str)).groupby('month')['order_total'].sum()\n",
        "monthly.plot(figsize=(12,4), title='Monthly Revenue')\n",
        "plt.xticks(rotation=60); plt.tight_layout(); plt.show()\n"
      ]
    },
    {
      "cell_type": "markdown",
      "metadata": {},
      "source": [
        "## Category and product analysis"
      ]
    },
    {
      "cell_type": "code",
      "execution_count": null,
      "metadata": {},
      "outputs": [],
      "source": [
        "x = items.merge(delivered[['order_id']], on='order_id').merge(products,on='product_id')\n",
        "category_rev = x.groupby('category')['line_revenue'].sum().sort_values(ascending=False)\n",
        "display(category_rev)\n",
        "display(x.groupby('product_name').agg(units=('quantity','sum'), revenue=('line_revenue','sum')).sort_values('revenue',ascending=False).head(10))\n"
      ]
    },
    {
      "cell_type": "markdown",
      "metadata": {},
      "source": [
        "## Customer behavior and segmentation"
      ]
    },
    {
      "cell_type": "code",
      "execution_count": null,
      "metadata": {},
      "outputs": [],
      "source": [
        "cust = delivered.groupby('customer_id').agg(order_count=('order_id','count'), revenue=('order_total','sum'), aov=('order_total','mean')).reset_index()\n",
        "cust['customer_type'] = cust['order_count'].map(lambda x: 'One-time' if x==1 else 'Repeat')\n",
        "cust['segment'] = 'Regular'\n",
        "cust.loc[cust['order_count']==1,'segment']='One-time'\n",
        "cust.loc[(cust['order_count']>=3)&(cust['revenue']>=7000),'segment']='Loyal'\n",
        "cust.loc[(cust['order_count']>=5)&(cust['revenue']>=15000),'segment']='Champions'\n",
        "display(cust.sort_values('revenue',ascending=False).head(10))\n",
        "display(cust.groupby('segment').agg(customers=('customer_id','count'), revenue=('revenue','sum')))\n"
      ]
    }
  ],
  "metadata": {
    "kernelspec": {
      "display_name": "Python 3",
      "language": "python",
      "name": "python3"
    },
    "language_info": {
      "name": "python",
      "version": "3"
    }
  },
  "nbformat": 4,
  "nbformat_minor": 5
}
