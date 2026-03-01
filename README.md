# Streamlit + PostgreSQL Project

## Setup Instructions

1. Clone the repo
2. Create virtual environment
   python -m venv venv
   source venv/bin/activate  (Mac/Linux)
   venv\Scripts\activate (Windows)

3. Install dependencies
   pip install -r requirements.txt

4. Create PostgreSQL database

5. Import database
   psql -U postgres -d your_db_name -f database/schema.sql
   psql -U postgres -d your_db_name -f database/seed.sql

6. Create .env file

7. Run
   streamlit run app.py

