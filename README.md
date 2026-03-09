# 🚀 Automated Policy Eligibility Engine

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-003B57?style=for-the-badge&logo=postgresql&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)
![Data Engineering](https://img.shields.io/badge/Data_Engineering-FF6F00?style=for-the-badge)

> An end-to-end, fully automated Medallion Architecture data pipeline built natively in Snowflake. This engine autonomously ingests raw datasets, validates records using Change Data Capture (CDC), evaluates eligibility against complex business rules using polyglot UDFs, and generates structured JSON decision payloads—all while securing PII with Zero-Trust access controls.



---

## 📑 Table of Contents
1. [Business Impact](#-business-impact)
2. [Architecture Deep Dive](#%EF%B8%8F-architecture-deep-dive)
3. [Enterprise Security](#-enterprise-security)
4. [Repository Structure](#-repository-structure)
5. [Getting Started (Deployment)](#-getting-started)

---

## 💡 Business Impact
* **100% Automation:** Eliminates manual data entry and batch processing delays. Decisions are generated within minutes of a file landing in the system.
* **Idempotent Processing:** Guarantees zero data duplication, no matter how many times source files are re-uploaded.
* **Scalable Rule Engine:** The `CROSS JOIN` matrix allows the business to add thousands of new customers and product rules without changing the underlying code.
* **Audit-Ready:** Every JSON decision payload contains the exact data points (age, claims history, KYC status) used to make the decision at that timestamp.

---

## 🏗️ Architecture Deep Dive

This project utilizes the **Medallion Architecture** pattern to progressively refine data.

| Layer | Purpose | Key Snowflake Technologies Used |
| :--- | :--- | :--- |
| 🥉 **Bronze (Raw)** | Ingestion & Auditability | `Internal Stages`, `Regex Pattern Matching`, scheduled `TASKS`, `VARIANT` types for JSON, `METADATA$FILENAME`. |
| 🥈 **Silver (Validated)**| CDC, Cleansing & Deduplication | `STREAMS` (Delta loads), `MERGE` (Upsert logic), `TRY_TO_DATE()`, Conditional Error Handling (`CASE`). |
| 🥇 **Gold (Curated)** | Business Logic & JSON Output | `Polyglot UDFs` (SQL & JavaScript), `CROSS JOIN` (Eligibility Matrix), `OBJECT_CONSTRUCT` (JSON generation). |

### 🛠️ Key Technical Implementations
* **Automated Ingestion:** Tasks run on a 1-minute schedule, using Regex (`PATTERN = '.*customer_master_.*\\.csv'`) to dynamically sweep internal stages for new files.
* **Semi-Structured Handling:** Native ingestion of JSON KYC and Watchlist data into `VARIANT` columns, later flattened using Snowflake's dot-notation (`kyc_data:status::VARCHAR`).
* **Multi-Language UDFs:** Complex "Refer/Reject/Approve" logic is handled by JavaScript UDFs natively executing inside Snowflake, allowing for complex `IF/ELSE` routing that SQL handles poorly.

<img width="1600" height="930" alt="image" src="https://github.com/user-attachments/assets/4580fc6c-80eb-4d3a-b578-04cbe24b000b" />


---

## 🔐 Enterprise Security

Data governance and Zero-Trust principles are baked into the core of this pipeline.

1. **Role-Based Access Control (RBAC):** * Strict hierarchy: `ACCOUNTADMIN` → `MANAGER` → `SALESPERSON` → `DATA_USER`.
   * Enforces the Principle of Least Privilege (e.g., Salespersons can only view the Gold decision schema, not the Silver raw data).
2. **Tag-Based Dynamic Data Masking:** * PII (Phone numbers, Emails, Names) is secured at the enterprise level using Snowflake Tags (`pii_data_tag`).
   * **Managers** see raw data: `919527123456`
   * **Sales/Users** see masked data: `***MASKED_PII***`

---

## 📂 Repository Structure

```text
policy-eligibility-engine/
├── README.md                   
├── ARCHITECTURE.md             
├── sample_data/                
│   ├── claims_history_50.csv
│   ├── customer_master_50.csv
│   ├── kyc_records_501.json
│   ├── product_family_rules_50.csv
│   ├── region_mapping_50.csv
│   └── watchlist_501.json
└── src/                        
    ├── 01_bronze/
    │   ├── 01_database_schema_stage_creation.sql
    │   ├── 02_raw_table_creation.sql
    │   ├── 03_copy_data_into_table.sql
    │   └── 04_task_creation.sql
    ├── 02_silver/
    │   ├── 01_validated_table_creation.sql
    │   ├── 02_merge_logic.sql
    │   ├── 03_stream_creation.sql
    │   └── 04_task_creation.sql
    └── 03_gold/
        ├── 01_output_table_creation.sql
        ├── 02_udf_creation.sql
        ├── 03_decision_engine_task.sql
        ├── 04_rbac.sql
        └── 05_tag_and_masking.sql
```

## 🚀 Getting Started

Prerequisites

- A Snowflake account (Free trial works perfectly).
- SnowSQL CLI installed on your local machine.

Deployment Steps

1. Clone the repository:
   ```bash
   git clone [https://github.com/DevanshuSawarkar/policy-eligibility-engine.git](https://github.com/DevanshuSawarkar/policy-eligibility-engine.git)
   cd policy-eligibility-engine
   ```

2. Setup the Environment:
Execute the scripts in src/00_setup/ and src/01_bronze/ via the Snowflake UI to create your databases, schemas, stages, and raw tables.

3. Upload Sample Data:
Use SnowSQL to push the sample data into your internal stage:
   ```sql
   PUT file://./sample_data/customer_master_50.csv @policy_engine_db.bronze.policy_engine_stage AUTO_COMPRESS=TRUE;
   ```

4. Deploy Pipeline Logic:
Run the scripts in src/02_silver/ and src/03_gold/ to build the Streams, MERGE statements, UDFs, and the final Rule Engine.

5. Turn on Automation!
Wake up your pipeline by resuming the tasks:
   ```sql
   ALTER TASK automate_bronze_customer_master RESUME;
   ALTER TASK process_customer_master_task RESUME;
   ALTER TASK decision_engine_task RESUME;
   ```


_Sit back and watch the data flow from Raw to Curated JSON autonomously!_

## 🫂 Team Members
- [Devanshu Sawarkar](https://github.com/DevanshuSawarkar)
- [Atharva Kale](https://github.com/AtharvaKale1)
- [Shreyas Daduria](https://github.com/shreyashD0810)



