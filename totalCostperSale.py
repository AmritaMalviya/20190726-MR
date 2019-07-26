import pandas as pd


# reading the csv files
mdf=pd.read_csv('data/marketing_cost.csv')
sdf = pd.read_csv('data/Sales_Data.csv')


# changing the case of the column headers
mdf["channel"] = mdf["channel"].str.title()
mdf["month"] = mdf["month"].str.title()
# mdf["total_cost"] = mdf["total_cost"].str.title()

# slicing the Month column to get just the first 3 characters
mdf['month'] = mdf['month'].str.slice(0, 3)

# string the channel names for any white spaces
mdf['channel'] = mdf['channel'].str.strip()

# Clearing interger files of columns 
mdf['total_cost'] = mdf['total_cost'].str.replace(",","").astype(float)
mdf.head(10)



# changing the case of the column headers
sdf["channel"] = sdf["channel"].str.title()
sdf["month"] = sdf["month"].str.title()
#sdf["year"] = sdf["year"].str.title()
#sdf["total_sales"] = sdf["total_sales"].str.title()

# slicing the Month column to get just the first 3 characters
sdf['month'] = sdf['month'].str.slice(0, 3)

# string the channel names for any white spaces
sdf['channel'] = sdf['channel'].str.strip()

sdf.head(5)


result = pd.merge(sdf,mdf, on =['channel', 'month'])


result['cost_per_sale'] = result['total_cost'].div(result['total_sales'])
result = result[['channel', 'month', 'year', 'total_cost', 'total_sales', 'cost_per_sale']]



result = result.sort_values(['year','month'])




print(result)



result.to_csv(r'data/results.csv', index = False)

