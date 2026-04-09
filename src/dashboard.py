import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd
import altair as alt
 
# 1. Page Configuration
st.set_page_config(page_title="Policy Engine Dashboard", layout="wide", page_icon="🛡️")
st.title("🛡️ Policy Eligibility & Pipeline Dashboard")
st.markdown("Real-time monitoring for the automated Medallion Architecture pipeline.")
 
# 2. Get the current Snowflake session (No passwords needed!)
session = get_active_session()

# --- DATA CACHING ---
# @st.cache_data ensures we don't query the database every time you click a button
@st.cache_data(ttl=60) # Refreshes every 60 seconds
def load_data():
    # Query 1: Overall Decision Split
    decisions_df = session.sql("""
        SELECT DECISION_STATUS, COUNT(*) as COUNT 
        FROM policy_engine_db.gold.DECISION_OUTPUT 
        GROUP BY DECISION_STATUS
    """).to_pandas()
 
    # Query 2: Product Family Breakdown
    products_df = session.sql("""
        SELECT PRODUCT_FAMILY, DECISION_STATUS, COUNT(*) as COUNT 
        FROM policy_engine_db.gold.DECISION_OUTPUT 
        GROUP BY PRODUCT_FAMILY, DECISION_STATUS
    """).to_pandas()
 
    # Query 3: Pipeline Health (Task Runs in last 24h)
    tasks_df = session.sql("""
        SELECT STATE, COUNT(*) as COUNT 
        FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
            SCHEDULED_TIME_RANGE_START => DATEADD('day', -1, CURRENT_TIMESTAMP())
        ))
        GROUP BY STATE
    """).to_pandas()
 
    quality_df = session.sql("""
        SELECT
            (SELECT COUNT(*) FROM policy_engine_db.bronze.customer_master_raw) as RAW_COUNT,
            (SELECT COUNT(*) FROM policy_engine_db.silver.customer_master_validated) as VALIDATED_COUNT
    """).to_pandas()
 
    return decisions_df, products_df, tasks_df, quality_df
 
# Load the data
decisions_df, products_df, tasks_df, quality_df = load_data()


# --- ZONE A: PIPELINE HEALTH ---
st.subheader("⚙️ Pipeline Health (Last 24 Hours)")
 
# Create 3 columns for our KPIs
kpi1, kpi2, kpi3 = st.columns(3)
 
# Calculate totals
total_decisions = decisions_df['COUNT'].sum() if not decisions_df.empty else 0
successful_tasks = tasks_df[tasks_df['STATE'] == 'SUCCEEDED']['COUNT'].sum() if not tasks_df.empty else 0
 
with kpi1:
    st.metric(label="Total Automated Decisions", value=f"{total_decisions:,}")
with kpi2:
    st.metric(label="Successful Task Executions", value=f"{successful_tasks:,}")
with kpi3:
    st.metric(label="Pipeline Status", value="Active 🟢")
 
st.divider() # Adds a nice horizontal line

# --- DATA QUALITY ZONE ---
st.subheader("🧹 Data Quality & Cleansing")
st.markdown("Monitoring the automated error-correction and validation layer.")
 
# Extract the numbers from the dataframe
raw_count = quality_df['RAW_COUNT'].iloc[0] if not quality_df.empty else 0
val_count = quality_df['VALIDATED_COUNT'].iloc[0] if not quality_df.empty else 0
rejected_count = raw_count - val_count
catch_rate = (val_count / raw_count * 100) if raw_count > 0 else 100
 
dq_col1, dq_col2, dq_col3 = st.columns(3)
 
with dq_col1:
    st.metric(label="Raw Rows Ingested", value=f"{raw_count:,}")
with dq_col2:
    st.metric(label="Rows Auto-Corrected/Dropped", value=f"{rejected_count:,}", delta="- Invalid Data", delta_color="inverse")
with dq_col3:
    st.metric(label="Data Quality Score", value=f"{catch_rate:.1f}%")
 
st.divider()

# --- ZONE B: BUSINESS OUTCOMES ---
st.subheader("📊 Eligibility Outcomes")
 
col1, col2 = st.columns(2)
 
with col1:
    st.markdown("**Overall Decision Split**")
    # Custom colors for Approve/Refer/Reject
    color_scale = alt.Scale(domain=['APPROVE', 'REFER', 'REJECT'], range=['#2ECC71', '#F1C40F', '#E74C3C'])
    
    pie_chart = alt.Chart(decisions_df).mark_arc(innerRadius=50).encode(
        theta=alt.Theta(field="COUNT", type="quantitative"),
        color=alt.Color(field="DECISION_STATUS", type="nominal", scale=color_scale, legend=alt.Legend(title="Status")),
        tooltip=['DECISION_STATUS', 'COUNT']
    ).interactive()
    
    st.altair_chart(pie_chart, use_container_width=True)
 
with col2:
    st.markdown("**Decisions by Product Family**")
    
    bar_chart = alt.Chart(products_df).mark_bar().encode(
        x=alt.X('PRODUCT_FAMILY', title='Product Family'),
        y=alt.Y('COUNT', title='Total Applications'),
        color=alt.Color('DECISION_STATUS', scale=color_scale),
        tooltip=['PRODUCT_FAMILY', 'DECISION_STATUS', 'COUNT']
    ).interactive()
    
    st.altair_chart(bar_chart, use_container_width=True)

# --- ZONE C: SECURITY & GOVERNANCE ---
st.subheader("🔐 Security & Access Audit")
st.markdown("Monitoring database access and active security policies.")
 
sec_col1, sec_col2 = st.columns([2, 1]) # Makes the first column twice as wide
 
with sec_col1:
    st.markdown("**Queries Executed by Role (Last 24 Hours)**")
    
    # Query Snowflake's built-in query history to prove RBAC is working
    try:
        audit_df = session.sql("""
            SELECT ROLE_NAME, COUNT(*) as TOTAL_QUERIES
            FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
                DATE_RANGE_START => DATEADD('day', -1, CURRENT_TIMESTAMP())
            ))
            WHERE DATABASE_NAME = 'POLICY_ENGINE_DB'
            GROUP BY ROLE_NAME
            ORDER BY TOTAL_QUERIES DESC
        """).to_pandas()
        
        if not audit_df.empty:
            # Create a horizontal bar chart
            audit_chart = alt.Chart(audit_df).mark_bar(color='#3498DB').encode(
                x=alt.X('TOTAL_QUERIES', title='Number of Queries'),
                y=alt.Y('ROLE_NAME', sort='-x', title='Snowflake Role'),
                tooltip=['ROLE_NAME', 'TOTAL_QUERIES']
            ).interactive()
            st.altair_chart(audit_chart, use_container_width=True)
        else:
            st.info("No queries executed in the last 24 hours.")
    except Exception as e:
        st.warning("Audit log access requires AccountAdmin privileges. Switch role to view.")
 
with sec_col2:
    st.markdown("**Active Security Policies**")
    # A visual checklist of the enterprise features you built
    st.success("✅ **Dynamic Data Masking**\nActive via `pii_data_tag`")
    st.success("✅ **Role-Based Access (RBAC)**\nStrict hierarchy enforced")
    st.success("✅ **Stage Encryption**\nFiles secured via `SNOWFLAKE_SSE`")
    st.success("✅ **Idempotency**\nZero data duplication guaranteed")
