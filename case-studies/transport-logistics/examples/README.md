# Customer document example

`customers.json` is a synthetic, independently constructed example of the document structure expected after Oracle setup. It is **not a captured Oracle query result**. Static checks reconcile its 6 customers, 33 nested quotes, 20 assigned jobs and effective paid/unpaid totals against the curated SQL fixture and retained cancellation quote.

Only customers with quotes appear. The MongoDB demonstration then adds customer 1001 and quote 2002, producing a separate seven-customer document state. That extra customer is not claimed to be synchronized back into Oracle.

Quote costs and revised job costs are distinct. The document format preserves display strings such as `$1,200.00` and `-`; it lacks per-quote payment state, so paid/unpaid totals cannot be independently recomputed from the JSON alone. The static checker uses the SQL payment flags to reconcile those totals.

Use the [export and conversion instructions](../../../docs/SETUP.md) to replace this fixture with genuinely executed Oracle output. Exported documents and generated arrays are ignored by Git.
