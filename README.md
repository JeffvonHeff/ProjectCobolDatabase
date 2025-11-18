# COBOL Invoice Generator with PostgreSQL

This project demonstrates how to connect a COBOL application to a local PostgreSQL database and build a printable-style invoice using live data. It is intentionally small but showcases a modern toolchain around a legacy language: GNUCobol handles compilation, ECPG (the PostgreSQL embedded SQL pre-compiler) mediates the SQL calls, and a handful of SQL scripts prepare sample data.

## Project layout

```
.
├── README.md               # Project overview and instructions
├── sql/
│   └── setup.sql           # Schema and random sample data
├── src/
│   └── invoice_generator.cob  # Main COBOL program (embedded SQL)
├── scripts/
│   └── run_invoice.sh      # Helper for compiling and running the sample
└── build/                  # Compilation artifacts live here (gitignored)
```

## Prerequisites

1. **PostgreSQL 14+** with local access.
2. **GNUCobol** (a.k.a. `cobc`) built with PostgreSQL support. On Ubuntu you can install the dependencies with:

   ```bash
   sudo apt update
   sudo apt install -y gnucobol postgresql postgresql-contrib postgresql-client ecpg
   ```

3. **Database credentials** exposed via environment variables so the COBOL program can connect without recompilation:

   ```bash
   export PGDATABASE=cobol_invoice
   export PGUSER=cobol_dev
   export PGPASSWORD=secret
   export PGHOST=localhost
   export PGPORT=5432
   ```

## Database setup with random example data

The `sql/setup.sql` script creates four tables (`customers`, `products`, `invoice_headers`, and `invoice_lines`) and loads a curated set of records that look realistic enough for demo invoices. Run it against a clean database that matches the `PGDATABASE` variable you exported above:

```bash
createdb "$PGDATABASE"
psql "$PGDATABASE" -f sql/setup.sql
```

> **Tip:** the script is idempotent thanks to `DROP TABLE IF EXISTS`, so you can re-run it while iterating.

### Running the SQL setup against PostgreSQL in Docker

If you prefer to keep PostgreSQL isolated inside Docker, follow these steps to run the `sql/setup.sql` script inside the container:

1. **Start a PostgreSQL container** using the official image and expose it on the default port so that local tools (and the COBOL program) can connect:

   ```bash
   docker run -d --name cobol-postgres \
     -e POSTGRES_USER=cobol_dev \
     -e POSTGRES_PASSWORD=secret \
     -e POSTGRES_DB=cobol_invoice \
     -p 5432:5432 postgres:15
   ```

2. **Copy the setup script into the container** (any temporary path works):

   ```bash
   docker cp sql/setup.sql cobol-postgres:/tmp/setup.sql
   ```

3. **Execute the script with `psql` inside the running container, feeding it the credentials defined above:**

   ```bash
   docker exec -it cobol-postgres \
     psql -U cobol_dev -d cobol_invoice -f /tmp/setup.sql
   ```

4. **(Optional) Confirm the tables exist** by running a quick query:

   ```bash
   docker exec -it cobol-postgres \
     psql -U cobol_dev -d cobol_invoice -c '\dt'
   ```

With those steps complete, the COBOL program can connect to `localhost:5432` using the same `PG*` environment variables listed above.

## Building and running the COBOL invoice generator

The helper script `scripts/run_invoice.sh` compiles the COBOL program (placing the executable in `build/invoice_generator`) and then runs it for a specific invoice ID. The script accepts a single optional argument – the invoice ID – and defaults to `1`.

```bash
./scripts/run_invoice.sh           # builds and prints invoice 1
./scripts/run_invoice.sh 2         # builds and prints invoice 2
```

### What the COBOL program does

* Reads database credentials from `PG*` environment variables.
* Connects to PostgreSQL using embedded SQL (`EXEC SQL ... END-EXEC`).
* Fetches header information (customer, invoice metadata) and detail lines for the requested invoice.
* Calculates totals and prints a formatted invoice to standard output that you can redirect to a PDF generator or printer.

A successful run prints something similar to:

```
==========================================
            COBOL INVOICE #INV-1002
==========================================
Customer:  Nikki Navarro
Email:     nikki.navarro@example.com
Company:   Blue Marble Analytics

Invoice Date : 2024-04-12    Due Date : 2024-05-12
Payment Terms: Net 30

Line Items
------------------------------------------
Qty  Description                     Price       Amount
  2  Premium Support Retainer     1200.00     2400.00
  5  Analytics Workshop Pass        75.00      375.00
------------------------------------------
Subtotal                                      2775.00
Tax (8.50%)                                    235.88
Grand Total                                  3010.88

Notes: Thanks for partnering with us on the Q2 enablement workshops.
```

## Extending the demo

* Add `UPDATE` statements for marking invoices as sent/paid.
* Pipe the COBOL output into LaTeX or a PDF template engine for polished documents.
* Replace environment variables with a configuration table so the program can manage multiple tenants.

Feel free to fork and adapt the project—COBOL can still surprise people when paired with a modern stack!
