       IDENTIFICATION DIVISION.
       PROGRAM-ID. INVOICE-GENERATOR.
       AUTHOR. OPENAI-DEMO.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. GNUCOBOL.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INVOICE-FILE ASSIGN TO "invoice.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

       FD  INVOICE-FILE.
       01  INVOICE-RECORD       PIC X(200).

       WORKING-STORAGE SECTION.

       EXEC SQL INCLUDE sqlca END-EXEC.

       EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01  DB-NAME             PIC X(64).
       01  DB-USER             PIC X(64).
       01  DB-PASSWORD         PIC X(64).
       01  DB-HOST             PIC X(64).
       01  DB-PORT             PIC X(10).
       01  DB-CONNECTION-STRING PIC X(256).

       01  WS-INVOICE-ID       PIC S9(9) COMP-5 VALUE 1.
       01  WS-INVOICE-NUMBER   PIC X(20).
       01  WS-CUSTOMER-NAME    PIC X(60).
       01  WS-COMPANY-NAME     PIC X(60).
       01  WS-CUSTOMER-EMAIL   PIC X(60).
       01  WS-INVOICE-DATE     PIC X(10).
       01  WS-DUE-DATE         PIC X(10).
       01  WS-PAYMENT-TERMS    PIC X(30).
       01  WS-INVOICE-NOTES    PIC X(200).
       01  WS-TAX-RATE         PIC S9V99.

       01  WS-LINE-DESC        PIC X(40).
       01  WS-LINE-QTY         PIC 9(5).
       01  WS-LINE-PRICE       PIC S9(7)V99.
       01  WS-LINE-AMOUNT      PIC S9(9)V99.

       01  WS-SUBTOTAL         PIC S9(9)V99 VALUE 0.
       01  WS-TAX-AMOUNT       PIC S9(9)V99 VALUE 0.
       01  WS-GRAND-TOTAL      PIC S9(9)V99 VALUE 0.
       EXEC SQL END DECLARE SECTION END-EXEC.

       01  ARGUMENT-COUNT      PIC 9(4) COMP.
       01  ARGUMENT-VALUE      PIC X(20).

       01  WS-LINE-QTY-DISP    PIC ZZ9.
       01  WS-LINE-PRICE-DISP  PIC Z(5)9.99.
       01  WS-LINE-AMT-DISP    PIC Z(6)9.99.
       01  WS-SUBTOTAL-DISP    PIC Z(7)9.99.
       01  WS-TAX-RATE-DISP    PIC ZZ9.99.
       01  WS-TAX-AMT-DISP     PIC Z(7)9.99.
       01  WS-TOTAL-DISP       PIC Z(7)9.99.
       01  WS-OUTPUT-LINE      PIC X(200).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           PERFORM INITIALIZE-ENVIRONMENT
           PERFORM OPEN-INVOICE-FILE
           PERFORM CONNECT-TO-DATABASE
           PERFORM FETCH-INVOICE-HEADER
           PERFORM DISPLAY-HEADER
           PERFORM FETCH-INVOICE-LINES
           PERFORM DISPLAY-TOTALS
           PERFORM DISCONNECT-DB
           PERFORM CLOSE-INVOICE-FILE
           GOBACK.

       INITIALIZE-ENVIRONMENT.
           MOVE SPACES TO DB-NAME DB-USER DB-PASSWORD DB-HOST DB-PORT
                           DB-CONNECTION-STRING
                           WS-INVOICE-NUMBER WS-CUSTOMER-NAME
                           WS-COMPANY-NAME WS-CUSTOMER-EMAIL
                           WS-INVOICE-DATE WS-DUE-DATE WS-PAYMENT-TERMS
                           WS-INVOICE-NOTES WS-LINE-DESC.
           ACCEPT DB-NAME FROM ENVIRONMENT "PGDATABASE".
           IF DB-NAME = SPACES MOVE "cobol_invoice" TO DB-NAME.
           ACCEPT DB-USER FROM ENVIRONMENT "PGUSER".
           IF DB-USER = SPACES MOVE "cobol_dev" TO DB-USER.
           ACCEPT DB-PASSWORD FROM ENVIRONMENT "PGPASSWORD".
           IF DB-PASSWORD = SPACES MOVE "secret" TO DB-PASSWORD.
           ACCEPT DB-HOST FROM ENVIRONMENT "PGHOST".
           ACCEPT DB-PORT FROM ENVIRONMENT "PGPORT".

           ACCEPT ARGUMENT-COUNT FROM ARGUMENT-NUMBER.
           IF ARGUMENT-COUNT > 0
               ACCEPT ARGUMENT-VALUE FROM ARGUMENT-VALUE
               COMPUTE WS-INVOICE-ID = FUNCTION NUMVAL(ARGUMENT-VALUE)
           ELSE
               MOVE 1 TO WS-INVOICE-ID
           END-IF.

       CONNECT-TO-DATABASE.
           IF DB-HOST NOT = SPACES AND DB-PORT NOT = SPACES
               STRING DB-NAME DELIMITED BY SPACE
                      "@" DELIMITED BY SIZE
                      DB-HOST DELIMITED BY SPACE
                      ":" DELIMITED BY SIZE
                      DB-PORT DELIMITED BY SPACE
                      INTO DB-CONNECTION-STRING
               END-STRING
           ELSE
               MOVE DB-NAME TO DB-CONNECTION-STRING
           END-IF
           DISPLAY "Connecting to database as " DB-USER "...".
           EXEC SQL
               CONNECT TO :DB-CONNECTION-STRING
               USER :DB-USER USING :DB-PASSWORD
           END-EXEC
           PERFORM CHECK-SQL-STATUS.

       FETCH-INVOICE-HEADER.
           EXEC SQL
             SELECT h.invoice_number,
                    c.name,
                    c.company,
                    c.email,
                    TO_CHAR(h.invoice_date, 'YYYY-MM-DD'),
                    TO_CHAR(h.due_date, 'YYYY-MM-DD'),
                    h.payment_terms,
                    COALESCE(h.notes, ''),
                    COALESCE(c.tax_rate_percent, 0)
               INTO :WS-INVOICE-NUMBER,
                    :WS-CUSTOMER-NAME,
                    :WS-COMPANY-NAME,
                    :WS-CUSTOMER-EMAIL,
                    :WS-INVOICE-DATE,
                    :WS-DUE-DATE,
                    :WS-PAYMENT-TERMS,
                    :WS-INVOICE-NOTES,
                    :WS-TAX-RATE
               FROM invoice_headers h
               JOIN customers c ON c.customer_id = h.customer_id
              WHERE h.invoice_id = :WS-INVOICE-ID
           END-EXEC
           PERFORM CHECK-SQL-STATUS.

       DISPLAY-HEADER.
           MOVE "==========================================" TO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           MOVE SPACES TO WS-OUTPUT-LINE.
           STRING "            COBOL INVOICE #" DELIMITED BY SIZE
                  WS-INVOICE-NUMBER DELIMITED BY SIZE
                  INTO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           MOVE "==========================================" TO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           MOVE SPACES TO WS-OUTPUT-LINE.
           STRING "Customer:  " DELIMITED BY SIZE
                  WS-CUSTOMER-NAME DELIMITED BY SIZE
                  INTO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           MOVE SPACES TO WS-OUTPUT-LINE.
           STRING "Email:     " DELIMITED BY SIZE
                  WS-CUSTOMER-EMAIL DELIMITED BY SIZE
                  INTO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           MOVE SPACES TO WS-OUTPUT-LINE.
           STRING "Company:   " DELIMITED BY SIZE
                  WS-COMPANY-NAME DELIMITED BY SIZE
                  INTO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           PERFORM OUTPUT-BLANK-LINE.
           MOVE SPACES TO WS-OUTPUT-LINE.
           STRING "Invoice Date : " DELIMITED BY SIZE
                  WS-INVOICE-DATE DELIMITED BY SIZE
                  "    Due Date : " DELIMITED BY SIZE
                  WS-DUE-DATE DELIMITED BY SIZE
                  INTO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           MOVE SPACES TO WS-OUTPUT-LINE.
           STRING "Payment Terms: " DELIMITED BY SIZE
                  WS-PAYMENT-TERMS DELIMITED BY SIZE
                  INTO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           PERFORM OUTPUT-BLANK-LINE.
           MOVE "Line Items" TO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           MOVE "------------------------------------------" TO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           MOVE "Qty  Description                     Price       Amount"
               TO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.

       FETCH-INVOICE-LINES.
           MOVE 0 TO WS-SUBTOTAL WS-TAX-AMOUNT WS-GRAND-TOTAL.
           EXEC SQL
             DECLARE line_cursor CURSOR FOR
               SELECT p.name,
                      l.quantity,
                      l.unit_price,
                      l.quantity * l.unit_price * (1 - (l.discount_pct / 100.0))
                 FROM invoice_lines l
                 JOIN products p ON p.product_id = l.product_id
                WHERE l.invoice_id = :WS-INVOICE-ID
                ORDER BY l.invoice_line_id
           END-EXEC.
           EXEC SQL OPEN line_cursor END-EXEC
           PERFORM CHECK-SQL-STATUS.

           PERFORM UNTIL SQLCODE = 100
               EXEC SQL
                   FETCH line_cursor
                    INTO :WS-LINE-DESC, :WS-LINE-QTY, :WS-LINE-PRICE, :WS-LINE-AMOUNT
               END-EXEC
               IF SQLCODE = 0
                   PERFORM DISPLAY-LINE
                   ADD WS-LINE-AMOUNT TO WS-SUBTOTAL
               ELSE
                   EXIT PERFORM
               END-IF
           END-PERFORM.

           EXEC SQL CLOSE line_cursor END-EXEC.
           IF SQLCODE NOT = 0 AND SQLCODE NOT = 100
               PERFORM CHECK-SQL-STATUS
           END-IF.

           COMPUTE WS-TAX-AMOUNT = WS-SUBTOTAL * (WS-TAX-RATE / 100).
           COMPUTE WS-GRAND-TOTAL = WS-SUBTOTAL + WS-TAX-AMOUNT.

       DISPLAY-LINE.
           MOVE WS-LINE-QTY TO WS-LINE-QTY-DISP.
           MOVE WS-LINE-PRICE TO WS-LINE-PRICE-DISP.
           MOVE WS-LINE-AMOUNT TO WS-LINE-AMT-DISP.
           MOVE SPACES TO WS-OUTPUT-LINE.
           STRING WS-LINE-QTY-DISP DELIMITED BY SIZE
                  "  " DELIMITED BY SIZE
                  WS-LINE-DESC(1:28) DELIMITED BY SIZE
                  "  " DELIMITED BY SIZE
                  WS-LINE-PRICE-DISP DELIMITED BY SIZE
                  "     " DELIMITED BY SIZE
                  WS-LINE-AMT-DISP DELIMITED BY SIZE
                  INTO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.

       DISPLAY-TOTALS.
           MOVE WS-SUBTOTAL TO WS-SUBTOTAL-DISP.
           MOVE WS-TAX-RATE TO WS-TAX-RATE-DISP.
           MOVE WS-TAX-AMOUNT TO WS-TAX-AMT-DISP.
           MOVE WS-GRAND-TOTAL TO WS-TOTAL-DISP.
           MOVE "------------------------------------------" TO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           MOVE SPACES TO WS-OUTPUT-LINE.
           STRING "Subtotal                                      " DELIMITED BY SIZE
                  WS-SUBTOTAL-DISP DELIMITED BY SIZE
                  INTO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           MOVE SPACES TO WS-OUTPUT-LINE.
           STRING "Tax (" DELIMITED BY SIZE
                  WS-TAX-RATE-DISP DELIMITED BY SIZE
                  "%)                               " DELIMITED BY SIZE
                  WS-TAX-AMT-DISP DELIMITED BY SIZE
                  INTO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           MOVE SPACES TO WS-OUTPUT-LINE.
           STRING "Grand Total                                  " DELIMITED BY SIZE
                  WS-TOTAL-DISP DELIMITED BY SIZE
                  INTO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.
           PERFORM OUTPUT-BLANK-LINE.
           MOVE SPACES TO WS-OUTPUT-LINE.
           STRING "Notes: " DELIMITED BY SIZE
                  WS-INVOICE-NOTES DELIMITED BY SIZE
                  INTO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.

       DISCONNECT-DB.
           EXEC SQL COMMIT WORK END-EXEC.
           EXEC SQL DISCONNECT ALL END-EXEC.

       OPEN-INVOICE-FILE.
           OPEN OUTPUT INVOICE-FILE.

       CLOSE-INVOICE-FILE.
           CLOSE INVOICE-FILE.

       OUTPUT-LINE.
           DISPLAY WS-OUTPUT-LINE.
           MOVE WS-OUTPUT-LINE TO INVOICE-RECORD.
           WRITE INVOICE-RECORD.

       OUTPUT-BLANK-LINE.
           MOVE SPACES TO WS-OUTPUT-LINE.
           PERFORM OUTPUT-LINE.

       CHECK-SQL-STATUS.
           IF SQLCODE NOT = 0 AND SQLCODE NOT = 100
               DISPLAY "SQL error: " SQLCODE " - " SQLERRMC
               STOP RUN
           END-IF.
       END PROGRAM INVOICE-GENERATOR.
