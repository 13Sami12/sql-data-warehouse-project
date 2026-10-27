"""Generates sample CRM/ERP CSV files with deliberate data quality issues.
Usage: python tools/generate_sample_data.py
"""
import csv, random, os
from datetime import date, timedelta

random.seed(42)
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "datasets")
CRM, ERP = os.path.join(ROOT, "source_crm"), os.path.join(ROOT, "source_erp")

def w(path, header, rows):
    with open(path, "w", newline="", encoding="utf-8") as f:
        cw = csv.writer(f, lineterminator="\n"); cw.writerow(header); cw.writerows(rows)

first = ["John","Anna","Peter","Maria","Ivan","Elena","David","Sara","Georgi","Nina","Mark","Laura","Tom","Eva","Alex","Julia"]
last = ["Smith","Ivanov","Brown","Petrova","Miller","Georgiev","Davis","Novak","Wilson","Koch","Taylor","Rossi"]
countries = [("DE","Germany"),("US","United States"),("USA","United States"),("AU","Australia"),("CA","Canada"),("FR","France"),("UK","United Kingdom")]

# ---- CRM customers + ERP customer data ----
N = 300
cust, erp_cust, erp_loc = [], [], []
for i in range(N):
    cid = 11000 + i
    key = f"AW{cid:08d}"
    fn, ln = random.choice(first), random.choice(last)
    ms = random.choice(["M","S","M","S","",None])
    g = random.choice(["M","F","M","F",None,""])
    created = date(2020,1,1) + timedelta(days=random.randint(0,900))
    cust.append([cid, key, " "+fn+" " if random.random()<.15 else fn, ln+(" " if random.random()<.1 else ""), ms or "", g or "", created])
    bd = date(1950,1,1) + timedelta(days=random.randint(0,18000))
    if random.random() < .03: bd = date(2099,1,1)           # future birthdate
    gen = random.choice(["Male","Female","M","F","",None])
    erp_cust.append([("NAS"+key) if random.random()<.3 else key, bd, gen or ""])
    c = random.choice(countries)
    ctry = c[0] if random.random()<.5 else c[1]
    erp_loc.append([f"AW-{cid:08d}", "" if random.random()<.05 else ctry])
for _ in range(10):                                           # duplicate customers
    r = list(random.choice(cust)); r[6] = r[6] + timedelta(days=random.randint(1,200)); cust.append(r)
cust.append(["", "", "Ghost", "User", "S", "M", date(2021,1,1)])  # null id
random.shuffle(cust)
w(f"{CRM}/cust_info.csv", ["cst_id","cst_key","cst_firstname","cst_lastname","cst_marital_status","cst_gndr","cst_create_date"], cust)
w(f"{ERP}/CUST_AZ12.csv", ["CID","BDATE","GEN"], erp_cust)
w(f"{ERP}/LOC_A101.csv", ["CID","CNTRY"], erp_loc)

# ---- Categories ----
cats = [("CO_RF","Components","Road Frames","Yes"),("CO_PE","Components","Pedals","No"),("CO_WH","Components","Wheels","Yes"),
        ("BI_MB","Bikes","Mountain Bikes","Yes"),("BI_RB","Bikes","Road Bikes","Yes"),("BI_TB","Bikes","Touring Bikes","No"),
        ("CL_HE","Clothing","Helmets","No"),("CL_JE","Clothing","Jerseys","No"),("AC_BC","Accessories","Bike Racks","No"),("AC_BT","Accessories","Bottles and Cages","No")]
w(f"{ERP}/PX_CAT_G1V2.csv", ["ID","CAT","SUBCAT","MAINTENANCE"], cats)

# ---- Products (with history) ----
prods, pid, pkeys = [], 200, []
for ci, cat in enumerate(cats):
    for k in range(4):
        base = f"{cat[0].replace('_','-')}-{chr(65+ci)}{k}{random.randint(10,99)}-{random.randint(10,60)}"
        cost = random.randint(5,900)
        line = random.choice(["M ","R","S","T"," T",""])
        name = f"{cat[2]} {k+1}"
        pkeys.append(base)
        if random.random() < .4:
            prods.append([pid, base, name, cost, line, date(2020,1,1), date(2019,12,31)]); pid += 1   # wrong end date
            prods.append([pid, base, name, int(cost*1.15), line, date(2022,1,1), ""]); pid += 1
        else:
            prods.append([pid, base, name, cost if random.random()>.05 else "", line, date(2020,1,1), ""]); pid += 1
w(f"{CRM}/prd_info.csv", ["prd_id","prd_key","prd_nm","prd_cost","prd_line","prd_start_dt","prd_end_dt"], prods)
price = {}
for r in prods: price[r[1]] = float(r[3] or 50)*1.8

# ---- Sales ----
rows = []
cids = [c[0] for c in cust if c[0] != ""]
for n in range(2000):
    o = date(2021,1,1) + timedelta(days=random.randint(0,1000))
    pk = random.choice(pkeys); qty = random.choice([1,1,1,2,3,4])
    pr = round(price[pk]); sales = pr*qty
    odi, sdi, ddi = [int(x.strftime("%Y%m%d")) for x in (o, o+timedelta(days=5), o+timedelta(days=12))]
    r = random.random()
    if r < .01: odi = 0
    elif r < .02: odi = 20210
    r = random.random()
    if r < .02: sales = ""
    elif r < .04: pr = ""
    elif r < .06: sales = -sales
    elif r < .08: sales = sales + 7
    rows.append([f"SO{50000+n}", pk[6:], random.choice(cids), odi, sdi, ddi, sales, qty, pr])
w(f"{CRM}/sales_details.csv", ["sls_ord_num","sls_prd_key","sls_cust_id","sls_order_dt","sls_ship_dt","sls_due_dt","sls_sales","sls_quantity","sls_price"], rows)
print("Done:", os.path.abspath(ROOT))
