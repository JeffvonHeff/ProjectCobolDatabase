-- Schema and seed data for the COBOL invoice demo.
-- Drop in reverse dependency order so the script stays idempotent.
DROP TABLE IF EXISTS invoice_lines;
DROP TABLE IF EXISTS invoice_headers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id      SERIAL PRIMARY KEY,
    name             TEXT NOT NULL,
    company          TEXT NOT NULL,
    email            TEXT NOT NULL,
    street           TEXT NOT NULL,
    city             TEXT NOT NULL,
    state            TEXT NOT NULL,
    postal_code      TEXT NOT NULL,
    tax_rate_percent NUMERIC(5,2) DEFAULT 0.00
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    sku        TEXT NOT NULL,
    name       TEXT NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL
);

CREATE TABLE invoice_headers (
    invoice_id      SERIAL PRIMARY KEY,
    invoice_number  TEXT UNIQUE NOT NULL,
    customer_id     INTEGER NOT NULL REFERENCES customers(customer_id),
    invoice_date    DATE NOT NULL,
    due_date        DATE NOT NULL,
    payment_terms   TEXT NOT NULL,
    notes           TEXT
);

CREATE TABLE invoice_lines (
    invoice_line_id SERIAL PRIMARY KEY,
    invoice_id      INTEGER NOT NULL REFERENCES invoice_headers(invoice_id) ON DELETE CASCADE,
    product_id      INTEGER NOT NULL REFERENCES products(product_id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10,2) NOT NULL,
    discount_pct    NUMERIC(5,2) DEFAULT 0.00
);

INSERT INTO customers (name, company, email, street, city, state, postal_code, tax_rate_percent) VALUES
    ('Luca Faraday', 'Northwind Robotics', 'luca.faraday@example.com', '812 Harbor Street', 'Seattle', 'WA', '98121', 10.00),
    ('Nikki Navarro', 'Blue Marble Analytics', 'nikki.navarro@example.com', '455 Silver Pine Rd', 'Boulder', 'CO', '80302', 8.50),
    ('Marina Soto', 'Verdant Retail Cooperative', 'marina.soto@example.com', '95 Magnolia Lane', 'Austin', 'TX', '78704', 8.25),
    ('Andre McGrath', 'Zenith Health Partners', 'andre.mcgrath@example.com', '4902 Cedar Avenue', 'Madison', 'WI', '53711', 5.50),
    ('Vivian Clarke', 'Signal Ridge Creative', 'vivian.clarke@example.com', '18 Summerview Terrace', 'Portland', 'OR', '97214', 0.00);

INSERT INTO products (sku, name, unit_price) VALUES
    ('SUP-1001', 'Premium Support Retainer', 1200.00),
    ('DEV-2010', 'Integration Engineering Block', 800.00),
    ('ANL-3300', 'Analytics Workshop Pass', 75.00),
    ('CNS-4400', 'Consulting Day Rate', 950.00),
    ('PLT-5500', 'Platform License - Monthly', 1500.00),
    ('IMPL-7780', 'Implementation Sprint', 6400.00);

INSERT INTO invoice_headers (invoice_number, customer_id, invoice_date, due_date, payment_terms, notes) VALUES
    ('INV-1001', 1, '2024-03-05', '2024-04-04', 'Net 30', 'Annual support retainer renewal.'),
    ('INV-1002', 2, '2024-04-12', '2024-05-12', 'Net 30', 'Thanks for partnering with us on the Q2 enablement workshops.'),
    ('INV-1003', 3, '2024-02-20', '2024-03-21', 'Net 30', 'Seasonal merchandising planning sprint.'),
    ('INV-1004', 4, '2024-05-01', '2024-06-01', 'Net 30', 'Quarterly advisory retainer.'),
    ('INV-1005', 5, '2024-01-15', '2024-02-14', 'Due on receipt', 'Creative direction sprint and platform license.');

INSERT INTO invoice_lines (invoice_id, product_id, quantity, unit_price, discount_pct) VALUES
    (1, 1, 1, 1200.00, 0.00),
    (1, 5, 1, 1500.00, 5.00),
    (2, 1, 2, 1200.00, 0.00),
    (2, 3, 5, 75.00, 0.00),
    (3, 6, 1, 6400.00, 10.00),
    (3, 3, 15, 75.00, 0.00),
    (4, 4, 6, 950.00, 0.00),
    (4, 2, 2, 800.00, 0.00),
    (5, 2, 4, 800.00, 7.50),
    (5, 5, 3, 1500.00, 0.00),
    (5, 4, 2, 950.00, 0.00);
