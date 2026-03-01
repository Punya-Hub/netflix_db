--
-- PostgreSQL database dump
--

\restrict Es726RAQc3ZlnTp32OPNKrb4ZsZaBUEHFT9nu8MOM3MbOSwdAM4CDB43R2LRR3u

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


--
-- Name: auto_set_watch_status(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.auto_set_watch_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.PercentageWatched >= 80 THEN
        NEW.Status := 'Completed';
    ELSE
        NEW.Status := 'Started';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.auto_set_watch_status() OWNER TO postgres;

--
-- Name: check_profile_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_profile_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (
        SELECT COUNT(*)
        FROM Profile
        WHERE UserID = NEW.UserID
    ) >= 5 THEN
        RAISE EXCEPTION 'A user cannot have more than 5 profiles';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_profile_limit() OWNER TO postgres;

--
-- Name: check_rating_completion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_rating_completion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM WatchHistory
        WHERE ProfileID = NEW.ProfileID
          AND ContentID = NEW.ContentID
          AND Status = 'Completed'
    ) THEN
        RAISE EXCEPTION 'Cannot rate content that is not completed';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_rating_completion() OWNER TO postgres;

--
-- Name: check_subscription_upgrade(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_subscription_upgrade() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    old_plan_name VARCHAR;
    new_plan_name VARCHAR;
BEGIN
    -- Get old plan name
    SELECT PlanName INTO old_plan_name
    FROM SubscriptionPlan
    WHERE PlanID = OLD.PlanID;

    -- Get new plan name
    SELECT PlanName INTO new_plan_name
    FROM SubscriptionPlan
    WHERE PlanID = NEW.PlanID;

    -- Disallow downgrade to Trial
    IF new_plan_name = 'Trial' AND old_plan_name <> 'Trial' THEN
        RAISE EXCEPTION 'Cannot downgrade to Trial plan';
    END IF;

    -- Disallow Annual → Monthly
    IF old_plan_name = 'Annual' AND new_plan_name = 'Monthly' THEN
        RAISE EXCEPTION 'Cannot downgrade from Annual to Monthly';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_subscription_upgrade() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: User; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."User" (
    userid integer NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    password character varying(100) NOT NULL,
    country character varying(50) NOT NULL,
    planid integer NOT NULL
);


ALTER TABLE public."User" OWNER TO postgres;

--
-- Name: User_userid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."User_userid_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."User_userid_seq" OWNER TO postgres;

--
-- Name: User_userid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."User_userid_seq" OWNED BY public."User".userid;


--
-- Name: content; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.content (
    contentid integer NOT NULL,
    title character varying(200) NOT NULL,
    type character varying(10) NOT NULL,
    releaseyear integer,
    language character varying(50) NOT NULL,
    agerating character varying(10),
    duration integer,
    is4kavailable boolean NOT NULL,
    CONSTRAINT content_duration_check CHECK ((duration > 0)),
    CONSTRAINT content_releaseyear_check CHECK ((releaseyear >= 1900)),
    CONSTRAINT content_type_check CHECK (((type)::text = ANY ((ARRAY['Movie'::character varying, 'Show'::character varying])::text[])))
);


ALTER TABLE public.content OWNER TO postgres;

--
-- Name: content_contentid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.content_contentid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.content_contentid_seq OWNER TO postgres;

--
-- Name: content_contentid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.content_contentid_seq OWNED BY public.content.contentid;


--
-- Name: contentgenre; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contentgenre (
    contentid integer NOT NULL,
    genreid integer NOT NULL
);


ALTER TABLE public.contentgenre OWNER TO postgres;

--
-- Name: episode; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.episode (
    contentid integer NOT NULL,
    seasonnumber integer NOT NULL,
    episodenumber integer NOT NULL,
    duration integer NOT NULL,
    CONSTRAINT episode_duration_check CHECK ((duration > 0)),
    CONSTRAINT episode_episodenumber_check CHECK ((episodenumber > 0)),
    CONSTRAINT episode_seasonnumber_check CHECK ((seasonnumber > 0))
);


ALTER TABLE public.episode OWNER TO postgres;

--
-- Name: genre; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genre (
    genreid integer NOT NULL,
    genrename character varying(50) NOT NULL
);


ALTER TABLE public.genre OWNER TO postgres;

--
-- Name: genre_genreid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.genre_genreid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.genre_genreid_seq OWNER TO postgres;

--
-- Name: genre_genreid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.genre_genreid_seq OWNED BY public.genre.genreid;


--
-- Name: payment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment (
    paymentid integer NOT NULL,
    userid integer NOT NULL,
    planid integer NOT NULL,
    amount numeric(8,2) NOT NULL,
    paymentdate date NOT NULL,
    paymentmethod character varying(50) NOT NULL,
    CONSTRAINT payment_amount_check CHECK ((amount >= (0)::numeric))
);


ALTER TABLE public.payment OWNER TO postgres;

--
-- Name: payment_paymentid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_paymentid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_paymentid_seq OWNER TO postgres;

--
-- Name: payment_paymentid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_paymentid_seq OWNED BY public.payment.paymentid;


--
-- Name: profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profile (
    profileid integer NOT NULL,
    profilename character varying(100) NOT NULL,
    kidsprofile boolean DEFAULT false NOT NULL,
    userid integer NOT NULL
);


ALTER TABLE public.profile OWNER TO postgres;

--
-- Name: profile_profileid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.profile_profileid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profile_profileid_seq OWNER TO postgres;

--
-- Name: profile_profileid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.profile_profileid_seq OWNED BY public.profile.profileid;


--
-- Name: rating; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rating (
    ratingid integer NOT NULL,
    profileid integer NOT NULL,
    contentid integer NOT NULL,
    ratingvalue integer NOT NULL,
    CONSTRAINT rating_ratingvalue_check CHECK (((ratingvalue >= 1) AND (ratingvalue <= 5)))
);


ALTER TABLE public.rating OWNER TO postgres;

--
-- Name: rating_ratingid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rating_ratingid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rating_ratingid_seq OWNER TO postgres;

--
-- Name: rating_ratingid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rating_ratingid_seq OWNED BY public.rating.ratingid;


--
-- Name: subscriptionplan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscriptionplan (
    planid integer NOT NULL,
    planname character varying(20) NOT NULL,
    price numeric(8,2) NOT NULL,
    durationindays integer NOT NULL,
    maxscreens integer NOT NULL,
    videoquality character varying(10) NOT NULL,
    CONSTRAINT subscriptionplan_durationindays_check CHECK ((durationindays > 0)),
    CONSTRAINT subscriptionplan_maxscreens_check CHECK ((maxscreens > 0)),
    CONSTRAINT subscriptionplan_price_check CHECK ((price >= (0)::numeric)),
    CONSTRAINT subscriptionplan_videoquality_check CHECK (((videoquality)::text = ANY ((ARRAY['HD'::character varying, '4K'::character varying])::text[])))
);


ALTER TABLE public.subscriptionplan OWNER TO postgres;

--
-- Name: subscriptionplan_planid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscriptionplan_planid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscriptionplan_planid_seq OWNER TO postgres;

--
-- Name: subscriptionplan_planid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscriptionplan_planid_seq OWNED BY public.subscriptionplan.planid;


--
-- Name: watchhistory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.watchhistory (
    watchid integer NOT NULL,
    profileid integer NOT NULL,
    contentid integer NOT NULL,
    seasonnumber integer,
    episodenumber integer,
    percentagewatched numeric(5,2),
    status character varying(20),
    watchdate date NOT NULL,
    CONSTRAINT watchhistory_percentagewatched_check CHECK ((percentagewatched >= (0)::numeric)),
    CONSTRAINT watchhistory_status_check CHECK (((status)::text = ANY ((ARRAY['Started'::character varying, 'Completed'::character varying])::text[])))
);


ALTER TABLE public.watchhistory OWNER TO postgres;

--
-- Name: watchhistory_watchid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.watchhistory_watchid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.watchhistory_watchid_seq OWNER TO postgres;

--
-- Name: watchhistory_watchid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.watchhistory_watchid_seq OWNED BY public.watchhistory.watchid;


--
-- Name: User userid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User" ALTER COLUMN userid SET DEFAULT nextval('public."User_userid_seq"'::regclass);


--
-- Name: content contentid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content ALTER COLUMN contentid SET DEFAULT nextval('public.content_contentid_seq'::regclass);


--
-- Name: genre genreid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genre ALTER COLUMN genreid SET DEFAULT nextval('public.genre_genreid_seq'::regclass);


--
-- Name: payment paymentid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment ALTER COLUMN paymentid SET DEFAULT nextval('public.payment_paymentid_seq'::regclass);


--
-- Name: profile profileid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile ALTER COLUMN profileid SET DEFAULT nextval('public.profile_profileid_seq'::regclass);


--
-- Name: rating ratingid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rating ALTER COLUMN ratingid SET DEFAULT nextval('public.rating_ratingid_seq'::regclass);


--
-- Name: subscriptionplan planid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptionplan ALTER COLUMN planid SET DEFAULT nextval('public.subscriptionplan_planid_seq'::regclass);


--
-- Name: watchhistory watchid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watchhistory ALTER COLUMN watchid SET DEFAULT nextval('public.watchhistory_watchid_seq'::regclass);


--
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."User" (userid, name, email, password, country, planid) FROM stdin;
2	Priya Mehta	priya@gmail.com	pass123	India	3
3	Arjun Patel	arjun@gmail.com	pass123	India	2
1	Rahul Sharma	rahul@gmail.com	pass123	India	3
4	Sneha Kapoor	sneha@gmail.com	pass123	India	2
5	Punya Pratap				2
\.


--
-- Data for Name: content; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.content (contentid, title, type, releaseyear, language, agerating, duration, is4kavailable) FROM stdin;
1	Inception	Movie	2010	English	PG-13	148	t
2	Interstellar	Movie	2014	English	PG-13	169	t
3	The Dark Knight	Movie	2008	English	PG-13	152	t
4	Stranger Things	Show	2016	English	TV-14	\N	t
5	Breaking Bad	Show	2008	English	TV-MA	\N	t
\.


--
-- Data for Name: contentgenre; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.contentgenre (contentid, genreid) FROM stdin;
1	1
1	3
2	3
3	1
3	5
4	3
4	5
5	2
\.


--
-- Data for Name: episode; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.episode (contentid, seasonnumber, episodenumber, duration) FROM stdin;
4	1	1	50
4	1	2	48
4	1	3	52
5	1	1	58
5	1	2	47
\.


--
-- Data for Name: genre; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.genre (genreid, genrename) FROM stdin;
1	Action
2	Drama
3	Sci-Fi
4	Comedy
5	Thriller
\.


--
-- Data for Name: payment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment (paymentid, userid, planid, amount, paymentdate, paymentmethod) FROM stdin;
1	1	2	499.00	2026-02-28	UPI
2	2	3	4999.00	2026-02-28	Credit Card
3	3	2	499.00	2026-02-28	Debit Card
4	4	1	0.00	2026-02-28	Free Trial
\.


--
-- Data for Name: profile; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profile (profileid, profilename, kidsprofile, userid) FROM stdin;
1	Rahul	f	1
2	Kids_Rahul	t	1
3	Priya_Main	f	2
4	Arjun_Main	f	3
5	Sneha_Main	f	4
\.


--
-- Data for Name: rating; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rating (ratingid, profileid, contentid, ratingvalue) FROM stdin;
1	1	1	5
2	1	4	4
3	4	5	5
\.


--
-- Data for Name: subscriptionplan; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subscriptionplan (planid, planname, price, durationindays, maxscreens, videoquality) FROM stdin;
1	Trial	0.00	30	1	HD
2	Monthly	499.00	30	2	HD
3	Annual	4999.00	365	4	4K
4	Quaterly	1000.00	90	3	4K
\.


--
-- Data for Name: watchhistory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.watchhistory (watchid, profileid, contentid, seasonnumber, episodenumber, percentagewatched, status, watchdate) FROM stdin;
1	1	1	\N	\N	95.00	Completed	2026-02-28
2	3	2	\N	\N	60.00	Started	2026-02-28
3	1	4	1	1	85.00	Completed	2026-02-28
4	1	4	1	2	40.00	Started	2026-02-28
5	4	5	1	1	90.00	Completed	2026-02-28
\.


--
-- Name: User_userid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."User_userid_seq"', 5, true);


--
-- Name: content_contentid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.content_contentid_seq', 5, true);


--
-- Name: genre_genreid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.genre_genreid_seq', 5, true);


--
-- Name: payment_paymentid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_paymentid_seq', 4, true);


--
-- Name: profile_profileid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profile_profileid_seq', 5, true);


--
-- Name: rating_ratingid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rating_ratingid_seq', 4, true);


--
-- Name: subscriptionplan_planid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subscriptionplan_planid_seq', 5, true);


--
-- Name: watchhistory_watchid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.watchhistory_watchid_seq', 5, true);


--
-- Name: User User_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_email_key" UNIQUE (email);


--
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (userid);


--
-- Name: content content_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content
    ADD CONSTRAINT content_pkey PRIMARY KEY (contentid);


--
-- Name: contentgenre contentgenre_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contentgenre
    ADD CONSTRAINT contentgenre_pkey PRIMARY KEY (contentid, genreid);


--
-- Name: episode episode_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.episode
    ADD CONSTRAINT episode_pkey PRIMARY KEY (contentid, seasonnumber, episodenumber);


--
-- Name: genre genre_genrename_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genre
    ADD CONSTRAINT genre_genrename_key UNIQUE (genrename);


--
-- Name: genre genre_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genre
    ADD CONSTRAINT genre_pkey PRIMARY KEY (genreid);


--
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (paymentid);


--
-- Name: profile profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile
    ADD CONSTRAINT profile_pkey PRIMARY KEY (profileid);


--
-- Name: rating rating_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rating
    ADD CONSTRAINT rating_pkey PRIMARY KEY (ratingid);


--
-- Name: rating rating_profileid_contentid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rating
    ADD CONSTRAINT rating_profileid_contentid_key UNIQUE (profileid, contentid);


--
-- Name: subscriptionplan subscriptionplan_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptionplan
    ADD CONSTRAINT subscriptionplan_pkey PRIMARY KEY (planid);


--
-- Name: subscriptionplan subscriptionplan_planname_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptionplan
    ADD CONSTRAINT subscriptionplan_planname_key UNIQUE (planname);


--
-- Name: watchhistory watchhistory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watchhistory
    ADD CONSTRAINT watchhistory_pkey PRIMARY KEY (watchid);


--
-- Name: watchhistory trigger_auto_watch_status; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_auto_watch_status BEFORE INSERT OR UPDATE ON public.watchhistory FOR EACH ROW EXECUTE FUNCTION public.auto_set_watch_status();


--
-- Name: profile trigger_profile_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_profile_limit BEFORE INSERT ON public.profile FOR EACH ROW EXECUTE FUNCTION public.check_profile_limit();


--
-- Name: rating trigger_rating_completion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_rating_completion BEFORE INSERT ON public.rating FOR EACH ROW EXECUTE FUNCTION public.check_rating_completion();


--
-- Name: User trigger_subscription_upgrade; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_subscription_upgrade BEFORE UPDATE OF planid ON public."User" FOR EACH ROW EXECUTE FUNCTION public.check_subscription_upgrade();


--
-- Name: User User_planid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_planid_fkey" FOREIGN KEY (planid) REFERENCES public.subscriptionplan(planid) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: contentgenre contentgenre_contentid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contentgenre
    ADD CONSTRAINT contentgenre_contentid_fkey FOREIGN KEY (contentid) REFERENCES public.content(contentid) ON DELETE CASCADE;


--
-- Name: contentgenre contentgenre_genreid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contentgenre
    ADD CONSTRAINT contentgenre_genreid_fkey FOREIGN KEY (genreid) REFERENCES public.genre(genreid) ON DELETE CASCADE;


--
-- Name: episode episode_contentid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.episode
    ADD CONSTRAINT episode_contentid_fkey FOREIGN KEY (contentid) REFERENCES public.content(contentid) ON DELETE CASCADE;


--
-- Name: payment payment_planid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_planid_fkey FOREIGN KEY (planid) REFERENCES public.subscriptionplan(planid) ON DELETE RESTRICT;


--
-- Name: payment payment_userid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_userid_fkey FOREIGN KEY (userid) REFERENCES public."User"(userid) ON DELETE CASCADE;


--
-- Name: profile profile_userid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile
    ADD CONSTRAINT profile_userid_fkey FOREIGN KEY (userid) REFERENCES public."User"(userid) ON DELETE CASCADE;


--
-- Name: rating rating_contentid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rating
    ADD CONSTRAINT rating_contentid_fkey FOREIGN KEY (contentid) REFERENCES public.content(contentid) ON DELETE CASCADE;


--
-- Name: rating rating_profileid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rating
    ADD CONSTRAINT rating_profileid_fkey FOREIGN KEY (profileid) REFERENCES public.profile(profileid) ON DELETE CASCADE;


--
-- Name: watchhistory watchhistory_contentid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watchhistory
    ADD CONSTRAINT watchhistory_contentid_fkey FOREIGN KEY (contentid) REFERENCES public.content(contentid) ON DELETE CASCADE;


--
-- Name: watchhistory watchhistory_contentid_seasonnumber_episodenumber_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watchhistory
    ADD CONSTRAINT watchhistory_contentid_seasonnumber_episodenumber_fkey FOREIGN KEY (contentid, seasonnumber, episodenumber) REFERENCES public.episode(contentid, seasonnumber, episodenumber) ON DELETE CASCADE;


--
-- Name: watchhistory watchhistory_profileid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watchhistory
    ADD CONSTRAINT watchhistory_profileid_fkey FOREIGN KEY (profileid) REFERENCES public.profile(profileid) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict Es726RAQc3ZlnTp32OPNKrb4ZsZaBUEHFT9nu8MOM3MbOSwdAM4CDB43R2LRR3u

