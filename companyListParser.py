import csv
import json

stockSymbolList = set()

with open('companylist.csv') as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=',')
    line_count = 0
    for row in csv_reader:
        if line_count != 0:
            if "^" not in row[0] and "." not in row[0]:
                stockSymbolList.add(row[0].strip())
        line_count += 1

with open('companylist1.csv') as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=',')
    line_count = 0
    for row in csv_reader:
        if line_count != 0:
            if "^" not in row[0] and "." not in row[0]:
                stockSymbolList.add(row[0].strip())
        line_count += 1

with open('companylist2.csv') as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=',')
    line_count = 0
    for row in csv_reader:
        if line_count != 0:
            if "^" not in row[0] and "." not in row[0]:
                stockSymbolList.add(row[0].strip())
        line_count += 1

stockSymbolList.remove("ABEOW")

with open('stockSymbolList.json', 'w') as outfile:
    json.dump(list(stockSymbolList), outfile)