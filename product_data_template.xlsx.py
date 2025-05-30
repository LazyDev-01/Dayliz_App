import openpyxl
from openpyxl import Workbook

wb = Workbook()
ws = wb.active
ws.title = "Products"

columns = [
    "Product Name",
    "Category",
    "Sub-category",
    "Brand",
    "Price",
    "Offer",
    "Unit",
    "Size"
]

ws.append(columns)

wb.save("product_data_template.xlsx") 