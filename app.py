import streamlit as st
import psycopg2
import pandas as pd

# -----------------------------
# DATABASE CONNECTION
# -----------------------------
def get_connection():
    return psycopg2.connect(
        dbname="netflix_db",
        user="postgres",
        password="postgres",
        host="localhost",
        port="5432"
    )

# -----------------------------
# PAGE CONFIG
# -----------------------------
st.set_page_config(page_title="Netflix DB Admin", layout="wide")

st.sidebar.title("🎬 Netflix DB Admin")
menu = st.sidebar.radio("Navigation", [
    "Dashboard",
    "Tables",
    "Reports"
])

# -----------------------------
# DASHBOARD
# -----------------------------
if menu == "Dashboard":
    st.title("📊 Dashboard")

    conn = get_connection()
    cur = conn.cursor()

    cur.execute("SELECT COUNT(*) FROM \"User\"")
    total_users = cur.fetchone()[0]

    cur.execute("SELECT COUNT(*) FROM Content")
    total_content = cur.fetchone()[0]

    cur.execute("SELECT SUM(Amount) FROM Payment")
    total_revenue = cur.fetchone()[0] or 0

    col1, col2, col3 = st.columns(3)

    col1.metric("Total Users", total_users)
    col2.metric("Total Content", total_content)
    col3.metric("Total Revenue (₹)", total_revenue)

    conn.close()
# -----------------------------
# TABLES TAB
# -----------------------------
elif menu == "Tables":
    st.title("📁 Tables")

    table_tabs = st.tabs([
        "SubscriptionPlan",
        "User",
        "Profile",
        "Content",
        "Episode",
        "Payment",
        "WatchHistory",
        "Rating"
    ])
    with table_tabs[0]:
        st.subheader("SubscriptionPlan Table")
        conn = get_connection()

        if st.button("View All Plans"):
            df = pd.read_sql("SELECT * FROM SubscriptionPlan", conn)
            st.dataframe(df)

        st.divider()

        st.subheader("Add Plan")
        plan_name = st.text_input("Plan Name",key="subplan_add_plan_name")
        price = st.number_input("Price", min_value=0.0,key="subplan_add_price")
        duration = st.number_input("Duration (Days)", min_value=1,key="subplan_add_duration")
        screens = st.number_input("Max Screens", min_value=1,key="subplan_add_screens")
        quality = st.selectbox("Video Quality", ["HD", "4K"],key="subplan_add_quality")

        if st.button("Insert Plan"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO SubscriptionPlan
                    (PlanName, Price, DurationInDays, MaxScreens, VideoQuality)
                    VALUES (%s,%s,%s,%s,%s)
                """,(plan_name,price,duration,screens,quality))
                conn.commit()
                st.success("Plan inserted!")
            except Exception as e:
                st.error(e)

        st.divider()

        st.subheader("Update Plan")
        update_id = st.number_input("Plan ID", min_value=1,key="subplan_update_id")
        new_price = st.number_input("New Price", min_value=0.0,key="subplan_update_price")
        new_screens = st.number_input("New Max Screens", min_value=1,key="subplan_update_screens")

        if st.button("Update Plan"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    UPDATE SubscriptionPlan
                    SET Price=%s, MaxScreens=%s
                    WHERE PlanID=%s
                """,(new_price,new_screens,update_id))
                conn.commit()
                st.success("Plan updated!")
            except Exception as e:
                st.error(e)

        st.divider()

        st.subheader("Delete Plan")
        delete_id = st.number_input("Plan ID to Delete", min_value=1,key="subplan_delete_id")

        if st.button("Delete Plan"):
            try:
                cur = conn.cursor()
                cur.execute("DELETE FROM SubscriptionPlan WHERE PlanID=%s",(delete_id,))
                conn.commit()
                st.success("Plan deleted!")
            except Exception as e:
                st.error(e)

        conn.close()

    # ---------------- USER TABLE ----------------
    with table_tabs[1]:
        st.subheader("User Table")

        conn = get_connection()

        # VIEW RECORDS
        if st.button("View All Users", key="user_view_all"):
            query = """
                SELECT 
                    u.UserID,
                    u.Name,
                    u.Email,
                    u.Country,
                    sp.PlanName
                FROM "User" u
                JOIN SubscriptionPlan sp 
                    ON u.PlanID = sp.PlanID
            """
            df = pd.read_sql(query, conn)
            st.dataframe(df)

        st.divider()

        # INSERT USER
        st.subheader("Add User")

        name = st.text_input("Name",key="user_add_name")
        email = st.text_input("Email",key="user_add_email")
        password = st.text_input("Password",key="user_add_password")
        country = st.text_input("Country",key="user_add_country")
        plan_id = st.selectbox("Plan", [1, 2, 3],key="user_add_planid")

        if st.button("Insert User"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO "User"
                    (Name, Email, Password, Country, PlanID)
                    VALUES (%s, %s, %s, %s, %s)
                """, (name, email, password, country, plan_id))
                conn.commit()
                st.success("User inserted!")
            except Exception as e:
                st.error(e)

        st.divider()

        # UPDATE USER
        st.subheader("Update User (No ID change allowed)")

        update_id = st.number_input("User ID to Update", min_value=1,key="user_update_id")
        new_name = st.text_input("New Name",key="user_update_name")
        new_email = st.text_input("New Email",key="user_update_email")
        new_password = st.text_input("New Password",key="user_update_password")
        new_country = st.text_input("New Country",key="user_update_country")

        if st.button("Update User"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    UPDATE "User"
                    SET Name=%s, Email=%s, Country=%s, Password=%s 
                    WHERE UserID=%s
                """, (new_name, new_email, new_country,new_password, update_id))
                conn.commit()
                st.success("User updated!")
            except Exception as e:
                st.error(e)

        st.divider()

        # DELETE USER
        st.subheader("Delete User")

        delete_id = st.number_input("User ID to Delete", min_value=1,key="user_delete_id")

        if st.button("Confirm Delete User"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    DELETE FROM "User"
                    WHERE UserID=%s
                """, (delete_id,))
                conn.commit()
                st.success("User deleted!")
            except Exception as e:
                st.error(e)

        conn.close()
    with table_tabs[2]:
        st.subheader("Profile Table")
        conn = get_connection()

        if st.button("View All Profiles", key="profile_view_all"):
            query = """
                SELECT 
                    p.ProfileID,
                    p.ProfileName,
                    p.KidsProfile,
                    u.Name AS UserName
                FROM Profile p
                JOIN "User" u 
                    ON p.UserID = u.UserID
            """
            df = pd.read_sql(query, conn)
            st.dataframe(df)

        st.divider()

        st.subheader("Add Profile")
        profile_name = st.text_input("Profile Name",key="profile_add_name")
        kids = st.checkbox("Kids Profile",key="profile_add_kids")
        user_id = st.number_input("User ID", min_value=1,key="profile_add_id")

        if st.button("Insert Profile"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO Profile
                    (ProfileName, KidsProfile, UserID)
                    VALUES (%s,%s,%s)
                """,(profile_name,kids,user_id))
                conn.commit()
                st.success("Profile inserted!")
            except Exception as e:
                st.error(e)

        st.divider()

        st.subheader("Update Profile")
        update_id = st.number_input("Profile ID", min_value=1,key="profile_update_id")
        new_name = st.text_input("New Profile Name",key="profile_update_name")

        if st.button("Update Profile"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    UPDATE Profile
                    SET ProfileName=%s
                    WHERE ProfileID=%s
                """,(new_name,update_id))
                conn.commit()
                st.success("Profile updated!")
            except Exception as e:
                st.error(e)

        st.divider()

        st.subheader("Delete Profile")
        delete_id = st.number_input("Profile ID to Delete", min_value=1,key="profile_delete_id")

        if st.button("Delete Profile"):
            try:
                cur = conn.cursor()
                cur.execute("DELETE FROM Profile WHERE ProfileID=%s",(delete_id,))
                conn.commit()
                st.success("Profile deleted!")
            except Exception as e:
                st.error(e)

        conn.close()
    with table_tabs[3]:
        st.subheader("Content Table")
        conn = get_connection()

        if st.button("View All Content"):
            df = pd.read_sql("SELECT * FROM Content", conn)
            st.dataframe(df)

        st.divider()

        st.subheader("Add Content")
        title = st.text_input("Title")
        type_val = st.selectbox("Type",["Movie","Show"])
        year = st.number_input("Release Year",min_value=1900)
        language = st.text_input("Language")
        age = st.text_input("Age Rating")
        duration = st.number_input("Duration",min_value=1)
        is4k = st.checkbox("4K Available")

        if st.button("Insert Content"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO Content
                    (Title,Type,ReleaseYear,Language,AgeRating,Duration,Is4KAvailable)
                    VALUES (%s,%s,%s,%s,%s,%s,%s)
                """,(title,type_val,year,language,age,duration,is4k))
                conn.commit()
                st.success("Content inserted!")
            except Exception as e:
                st.error(e)

        st.divider()

        st.subheader("Update Content")
        update_id = st.number_input("Content ID",min_value=1)
        new_title = st.text_input("New Title")

        if st.button("Update Content"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    UPDATE Content
                    SET Title=%s
                    WHERE ContentID=%s
                """,(new_title,update_id))
                conn.commit()
                st.success("Content updated!")
            except Exception as e:
                st.error(e)

        st.divider()

        st.subheader("Delete Content")
        delete_id = st.number_input("Content ID to Delete",min_value=1)

        if st.button("Delete Content"):
            try:
                cur = conn.cursor()
                cur.execute("DELETE FROM Content WHERE ContentID=%s",(delete_id,))
                conn.commit()
                st.success("Content deleted!")
            except Exception as e:
                st.error(e)

        conn.close()
    
    with table_tabs[4]:
        st.subheader("Episode Table")
        conn = get_connection()

        if st.button("View All Episodes", key="episode_view_all"):
            query = """
                SELECT 
                    e.ContentID,
                    c.Title AS ShowName,
                    e.SeasonNumber,
                    e.EpisodeNumber,
                    e.Duration
                FROM Episode e
                JOIN Content c 
                    ON e.ContentID = c.ContentID
            """
            df = pd.read_sql(query, conn)
            st.dataframe(df)

        st.divider()

        st.subheader("Add Episode")
        content_id = st.number_input("Content ID", min_value=1, key="episode_add_content_id")
        season = st.number_input("Season Number", min_value=1, key="episode_add_season")
        episode = st.number_input("Episode Number", min_value=1, key="episode_add_episode")
        duration = st.number_input("Duration", min_value=1, key="episode_add_duration")

        if st.button("Insert Episode", key="episode_insert_btn"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO Episode
                    (ContentID,SeasonNumber,EpisodeNumber,Duration)
                    VALUES (%s,%s,%s,%s)
                """,(content_id,season,episode,duration))
                conn.commit()
                st.success("Episode inserted!")
            except Exception as e:
                st.error(e)

        conn.close()
    with table_tabs[5]:
        st.subheader("Payment Table")
        conn = get_connection()

        if st.button("View All Payments", key="payment_view_all"):
            query = """
                SELECT 
                    p.PaymentID,
                    u.Name AS UserName,
                    sp.PlanName,
                    p.Amount,
                    p.PaymentDate,
                    p.PaymentMethod
                FROM Payment p
                JOIN "User" u 
                    ON p.UserID = u.UserID
                JOIN SubscriptionPlan sp 
                    ON p.PlanID = sp.PlanID
            """
            df = pd.read_sql(query, conn)
            st.dataframe(df)

        st.divider()

        st.subheader("Add Payment")
        user_id = st.number_input("User ID", min_value=1, key="payment_add_user_id")
        plan_id = st.number_input("Plan ID", min_value=1, key="payment_add_plan_id")
        amount = st.number_input("Amount", min_value=0.0, key="payment_add_amount")
        method = st.text_input("Payment Method", key="payment_add_method")

        if st.button("Insert Payment", key="payment_insert_btn"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO Payment
                    (UserID,PlanID,Amount,PaymentDate,PaymentMethod)
                    VALUES (%s,%s,%s,CURRENT_DATE,%s)
                """,(user_id,plan_id,amount,method))
                conn.commit()
                st.success("Payment inserted!")
            except Exception as e:
                st.error(e)

        conn.close()
    with table_tabs[6]:
        st.subheader("WatchHistory Table")
        conn = get_connection()

        if st.button("View All WatchHistory", key="wh_view_all"):
            query = """
                SELECT 
                    wh.WatchID,
                    p.ProfileName,
                    c.Title,
                    wh.PercentageWatched,
                    wh.Status,
                    wh.WatchDate
                FROM WatchHistory wh
                JOIN Profile p 
                    ON wh.ProfileID = p.ProfileID
                JOIN Content c 
                    ON wh.ContentID = c.ContentID
            """
            df = pd.read_sql(query, conn)
            st.dataframe(df)

        st.divider()

        st.subheader("Add Watch History")
        profile_id = st.number_input("Profile ID", min_value=1, key="wh_add_profile_id")
        content_id = st.number_input("Content ID", min_value=1, key="wh_add_content_id")
        percent = st.number_input("Percentage Watched", min_value=0.0, max_value=100.0, key="wh_add_percent")

        if st.button("Insert Watch", key="wh_insert_btn"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO WatchHistory
                    (ProfileID,ContentID,PercentageWatched,WatchDate)
                    VALUES (%s,%s,%s,CURRENT_DATE)
                """,(profile_id,content_id,percent))
                conn.commit()
                st.success("Watch history inserted!")
            except Exception as e:
                st.error(e)

        conn.close()
    with table_tabs[7]:
        st.subheader("Rating Table")
        conn = get_connection()

        # ---------------- VIEW ----------------
        if st.button("View All Ratings", key="rating_view_all"):
            query = """
                SELECT 
                    r.RatingID,
                    p.ProfileName,
                    c.Title,
                    r.RatingValue
                FROM Rating r
                JOIN Profile p 
                    ON r.ProfileID = p.ProfileID
                JOIN Content c 
                    ON r.ContentID = c.ContentID
            """
            df = pd.read_sql(query, conn)
            st.dataframe(df)

        st.divider()

        # ---------------- INSERT ----------------
        st.subheader("Add Rating")

        profile_id = st.number_input(
            "Profile ID",
            min_value=1,
            key="rating_add_profile_id"
        )

        content_id = st.number_input(
            "Content ID",
            min_value=1,
            key="rating_add_content_id"
        )

        rating_value = st.number_input(
            "Rating (1-5)",
            min_value=1,
            max_value=5,
            key="rating_add_value"
        )

        if st.button("Insert Rating", key="rating_insert_btn"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO Rating
                    (ProfileID, ContentID, RatingValue)
                    VALUES (%s, %s, %s)
                """, (profile_id, content_id, rating_value))
                conn.commit()
                st.success("Rating inserted!")
            except Exception as e:
                st.error(e)

        st.divider()

        # ---------------- UPDATE ----------------
        st.subheader("Update Rating")

        rating_id = st.number_input(
            "Rating ID",
            min_value=1,
            key="rating_update_id"
        )

        new_value = st.number_input(
            "New Rating (1-5)",
            min_value=1,
            max_value=5,
            key="rating_update_value"
        )

        if st.button("Update Rating", key="rating_update_btn"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    UPDATE Rating
                    SET RatingValue=%s
                    WHERE RatingID=%s
                """, (new_value, rating_id))
                conn.commit()
                st.success("Rating updated!")
            except Exception as e:
                st.error(e)

        st.divider()

        # ---------------- DELETE ----------------
        st.subheader("Delete Rating")

        delete_id = st.number_input(
            "Rating ID to Delete",
            min_value=1,
            key="rating_delete_id"
        )

        if st.button("Delete Rating", key="rating_delete_btn"):
            try:
                cur = conn.cursor()
                cur.execute("""
                    DELETE FROM Rating
                    WHERE RatingID=%s
                """, (delete_id,))
                conn.commit()
                st.success("Rating deleted!")
            except Exception as e:
                st.error(e)

        conn.close()