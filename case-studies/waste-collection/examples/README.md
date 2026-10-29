# Synthetic collection example

The [data script](../sql/03-demo-data.sql) is a portfolio addition. It creates a street with no properties, a property with no bins, an owner awaiting an assignment, two successive contracts, a historically priced bin and two collection attempts. All contact details are non-contactable demonstration values.

The [reports](../sql/04-collection-report.sql) should show the original green-bin supply charge of 55 against a catalogue price of 65, a successful 62 kg collection charged at 0.18/kg (11.16), and an overweight landfill attempt with no collected weight and zero collection charge. These are calculations from the fixture, not executed query output.
