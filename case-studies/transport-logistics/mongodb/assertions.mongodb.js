// Portfolio addition: run against the fixture after customer-demo.mongodb.js.
if (db.getName() !== 'portfolio_transport') throw new Error('Wrong database');
function assertPortfolio(condition, message) { if (!condition) throw new Error(message); }
assertPortfolio(db.brm_customers.countDocuments({}) === 7, 'Expected six fixture customers plus the new customer');
const patrick = db.brm_customers.findOne({_id: 1001});
assertPortfolio(patrick.quotes.length === 1 && patrick.customer_stats.number_of_quotes === 1, 'Quote update must be atomic and unique');
assertPortfolio(patrick.customer_stats.total_paid_jobcost === '$3,200.00', 'Paid total mismatch');
assertPortfolio(db.brm_customers.countDocuments({'customer_address': /Melbourne/, 'customer_stats.number_of_quotes': {$gte: 2}}) === 2, 'Melbourne filter coverage');
for (const customer of db.brm_customers.find().toArray()) {
 assertPortfolio(customer.customer_stats.number_of_quotes === customer.quotes.length, 'Embedded quote count mismatch');
 assertPortfolio(customer.customer_stats.number_of_jobs === customer.quotes.filter(q => q.assigned_to_job === 'Y').length, 'Embedded job count mismatch');
 const ids = customer.quotes.map(q => q.quote_no);
 assertPortfolio(new Set(ids).size === ids.length, 'Duplicate embedded quote');
}
print('MongoDB runtime assertions passed');
