// Author's insert, filter, projection and single-document update, curated for mongosh.
// Portfolio additions: environment guard, external fixture and duplicate-quote protection.
if (db.getName() !== 'portfolio_transport') throw new Error('Use the disposable portfolio_transport database');
if (process.env.PORTFOLIO_RESET !== 'YES') throw new Error('Set PORTFOLIO_RESET=YES to reset the demo collection');
const fs = require('fs');
const fixturePath = process.env.PORTFOLIO_CUSTOMERS || 'case-studies/transport-logistics/examples/customers.json';
const customers = JSON.parse(fs.readFileSync(fixturePath, 'utf8'));
if (!Array.isArray(customers) || customers.length === 0) throw new Error('Expected a nonempty JSON array');
db.brm_customers.drop();
db.createCollection('brm_customers');
db.brm_customers.insertMany(customers);
// List all documents you added
printjson(db.brm_customers.find({}).toArray());

printjson(db.brm_customers.find(
    {
        "customer_address": /Melbourne/,
        "customer_stats.number_of_quotes": {"$gte": 2}
    },
    {
        "_id": 1,
        "customer_name": 1,
        "customer_address": 1,
        "customer_phone": 1,
        "customer_stats.number_of_quotes": 1,
        "customer_stats.number_of_jobs": 1,
        "customer_stats.total_paid_jobcost": 1,
        "customer_stats.total_unpaid_jobcost": 1
    }
).toArray());



// (i)  Add the new customer
db.brm_customers.insertOne({
    "_id": 1001,
    "customer_name": "Patrick Bosse",
    "customer_business": "-",
    "customer_address": "1001 Example Avenue, Melbourne, 3000",
    "customer_phone": "0000001001",
    "customer_stats": {
        "number_of_quotes": 0,
        "number_of_jobs": 0,
        "total_paid_jobcost": "-",
        "total_unpaid_jobcost": "-"
    },
    "quotes": []
});


// Show the customer details
printjson(db.brm_customers.find({"_id": 1001}).toArray());

// (ii) Add new quote
db.brm_customers.updateOne(
    {"_id": 1001, "quotes.quote_no": {"$ne": 2002}},
    {
        "$set": {
            "customer_stats.number_of_quotes": 1,
            "customer_stats.number_of_jobs": 1,
            "customer_stats.total_paid_jobcost": "$3,200.00",
            "customer_stats.total_unpaid_jobcost": "-"
        },
        "$push": {
            "quotes": {
                "quote_no": 2002,
                "quote_prepared_on": "01-Jun-2026",
                "preferred_start_date": "10-Jun-2026",
                "start_location": "Adelaide SA",
                "end_location": "Melbourne VIC",
                "quote_cost": "$3,200.00",
                "assigned_to_job": "Y",
                "job_cost": "$3,200.00"
            }
        }
    }
);

// Show the customer details
printjson(db.brm_customers.find({"_id": 1001}).toArray());
