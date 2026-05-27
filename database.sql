--
-- PostgreSQL database dump
--

\restrict OV8BRgR0reFeHnxyrSpUFYSfaIxdBhlbvzzQv41nMianWia4JZtovx2aZHSMtIP

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

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

ALTER TABLE ONLY public.staff DROP CONSTRAINT staff_salon_id_salons_id_fk;
ALTER TABLE ONLY public.services DROP CONSTRAINT services_salon_id_salons_id_fk;
ALTER TABLE ONLY public.salons DROP CONSTRAINT salons_owner_id_users_id_fk;
ALTER TABLE ONLY public.reviews DROP CONSTRAINT reviews_user_id_users_id_fk;
ALTER TABLE ONLY public.reviews DROP CONSTRAINT reviews_salon_id_salons_id_fk;
ALTER TABLE ONLY public.reviews DROP CONSTRAINT reviews_booking_id_bookings_id_fk;
ALTER TABLE ONLY public.favorites DROP CONSTRAINT favorites_user_id_users_id_fk;
ALTER TABLE ONLY public.favorites DROP CONSTRAINT favorites_salon_id_salons_id_fk;
ALTER TABLE ONLY public.bookings DROP CONSTRAINT bookings_user_id_users_id_fk;
ALTER TABLE ONLY public.bookings DROP CONSTRAINT bookings_staff_id_staff_id_fk;
ALTER TABLE ONLY public.bookings DROP CONSTRAINT bookings_service_id_services_id_fk;
ALTER TABLE ONLY public.bookings DROP CONSTRAINT bookings_salon_id_salons_id_fk;
ALTER TABLE ONLY public.admin_logs DROP CONSTRAINT admin_logs_admin_id_admins_id_fk;
ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
ALTER TABLE ONLY public.users DROP CONSTRAINT users_email_unique;
ALTER TABLE ONLY public.staff DROP CONSTRAINT staff_pkey;
ALTER TABLE ONLY public.services DROP CONSTRAINT services_pkey;
ALTER TABLE ONLY public.salons DROP CONSTRAINT salons_pkey;
ALTER TABLE ONLY public.reviews DROP CONSTRAINT reviews_pkey;
ALTER TABLE ONLY public.favorites DROP CONSTRAINT favorites_user_id_salon_id_pk;
ALTER TABLE ONLY public.categories DROP CONSTRAINT categories_pkey;
ALTER TABLE ONLY public.categories DROP CONSTRAINT categories_name_unique;
ALTER TABLE ONLY public.bookings DROP CONSTRAINT bookings_pkey;
ALTER TABLE ONLY public.admins DROP CONSTRAINT admins_pkey;
ALTER TABLE ONLY public.admins DROP CONSTRAINT admins_email_unique;
ALTER TABLE ONLY public.admin_logs DROP CONSTRAINT admin_logs_pkey;
ALTER TABLE public.users ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.staff ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.services ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.salons ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.reviews ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.categories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.bookings ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.admins ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.admin_logs ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE public.users_id_seq;
DROP TABLE public.users;
DROP SEQUENCE public.staff_id_seq;
DROP TABLE public.staff;
DROP SEQUENCE public.services_id_seq;
DROP TABLE public.services;
DROP SEQUENCE public.salons_id_seq;
DROP TABLE public.salons;
DROP SEQUENCE public.reviews_id_seq;
DROP TABLE public.reviews;
DROP TABLE public.favorites;
DROP SEQUENCE public.categories_id_seq;
DROP TABLE public.categories;
DROP SEQUENCE public.bookings_id_seq;
DROP TABLE public.bookings;
DROP SEQUENCE public.admins_id_seq;
DROP TABLE public.admins;
DROP SEQUENCE public.admin_logs_id_seq;
DROP TABLE public.admin_logs;
DROP TYPE public.user_role;
DROP TYPE public.booking_status;
--
-- Name: booking_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.booking_status AS ENUM (
    'pending',
    'accepted',
    'in_progress',
    'completed',
    'cancelled'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'user',
    'owner',
    'admin'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_logs (
    id integer NOT NULL,
    admin_id integer NOT NULL,
    action text NOT NULL,
    target text,
    details text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: admin_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_logs_id_seq OWNED BY public.admin_logs.id;


--
-- Name: admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins (
    id integer NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    phone text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins_id_seq OWNED BY public.admins.id;


--
-- Name: bookings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bookings (
    id integer NOT NULL,
    user_id integer NOT NULL,
    salon_id integer NOT NULL,
    service_id integer NOT NULL,
    staff_id integer,
    booking_date date NOT NULL,
    start_time text NOT NULL,
    end_time text,
    status public.booking_status DEFAULT 'pending'::public.booking_status NOT NULL,
    total_price real NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: bookings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bookings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bookings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bookings_id_seq OWNED BY public.bookings.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    name text NOT NULL,
    icon text DEFAULT 'scissors'::text NOT NULL,
    salon_count integer DEFAULT 0 NOT NULL
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: favorites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favorites (
    user_id integer NOT NULL,
    salon_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviews (
    id integer NOT NULL,
    user_id integer NOT NULL,
    salon_id integer NOT NULL,
    booking_id integer,
    rating integer NOT NULL,
    comment text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- Name: salons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.salons (
    id integer NOT NULL,
    name text NOT NULL,
    description text,
    owner_id integer NOT NULL,
    address text NOT NULL,
    city text NOT NULL,
    state text,
    lat real,
    lng real,
    phone text,
    image_url text,
    images text[] DEFAULT '{}'::text[] NOT NULL,
    avg_rating real DEFAULT 0 NOT NULL,
    total_reviews integer DEFAULT 0 NOT NULL,
    total_bookings integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_verified boolean DEFAULT false NOT NULL,
    open_time text,
    close_time text,
    total_seats integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: salons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.salons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: salons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.salons_id_seq OWNED BY public.salons.id;


--
-- Name: services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.services (
    id integer NOT NULL,
    salon_id integer NOT NULL,
    name text NOT NULL,
    description text,
    price real NOT NULL,
    duration_minutes integer DEFAULT 60 NOT NULL,
    category text,
    image_url text,
    is_active boolean DEFAULT true NOT NULL,
    discount_percent real,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.services_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;


--
-- Name: staff; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff (
    id integer NOT NULL,
    salon_id integer NOT NULL,
    name text NOT NULL,
    role text,
    specialization text,
    avatar_url text,
    is_available boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: staff_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.staff_id_seq OWNED BY public.staff.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    phone text,
    avatar_url text,
    role public.user_role DEFAULT 'user'::public.user_role NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: admin_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_logs ALTER COLUMN id SET DEFAULT nextval('public.admin_logs_id_seq'::regclass);


--
-- Name: admins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins ALTER COLUMN id SET DEFAULT nextval('public.admins_id_seq'::regclass);


--
-- Name: bookings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings ALTER COLUMN id SET DEFAULT nextval('public.bookings_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Name: salons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salons ALTER COLUMN id SET DEFAULT nextval('public.salons_id_seq'::regclass);


--
-- Name: services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services ALTER COLUMN id SET DEFAULT nextval('public.services_id_seq'::regclass);


--
-- Name: staff id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff ALTER COLUMN id SET DEFAULT nextval('public.staff_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: admin_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_logs (id, admin_id, action, target, details, created_at) FROM stdin;
1	1	UPDATE_SALON	Salon #3	Updated salon details: The Style Lab. Verified: true, Active: true	2026-05-23 20:41:38.542238+05:30
2	1	UPDATE_SALON	Salon #6	Updated salon details: Glow Beauty Studio. Verified: true, Active: true	2026-05-23 20:41:42.051403+05:30
\.


--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admins (id, name, email, password_hash, phone, created_at, updated_at) FROM stdin;
1	GlowBook Administrator	admin@glowbook.com	$2b$10$u7f8JjJ3h5IDtwqWGfZ5K.yBcPo4nkzrHET4VRjQNyqqzqvjAUmzy	+1 555-0900	2026-05-23 12:19:45.633714+05:30	2026-05-23 12:19:45.633714+05:30
\.


--
-- Data for Name: bookings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bookings (id, user_id, salon_id, service_id, staff_id, booking_date, start_time, end_time, status, total_price, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.categories (id, name, icon, salon_count) FROM stdin;
1	Hair & Styling	scissors	0
2	Nails	sparkles	0
3	Makeup	star	0
4	Massage	heart	0
5	Skincare	sun	0
6	Barber	user	0
\.


--
-- Data for Name: favorites; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.favorites (user_id, salon_id, created_at) FROM stdin;
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reviews (id, user_id, salon_id, booking_id, rating, comment, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: salons; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.salons (id, name, description, owner_id, address, city, state, lat, lng, phone, image_url, images, avg_rating, total_reviews, total_bookings, is_active, is_verified, open_time, close_time, total_seats, created_at, updated_at) FROM stdin;
1	Golden Scissors	Premium hair salon with top stylists and a luxurious atmosphere.	1	123 Fifth Avenue	New York	NY	40.7549	-73.984	+1 212-555-0101	https://images.unsplash.com/photo-1560066984-138dadb4c035?w=800	{https://images.unsplash.com/photo-1560066984-138dadb4c035?w=800,https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=800}	4.8	127	340	t	t	09:00	20:00	\N	2026-05-23 11:46:26.966242+05:30	2026-05-23 11:46:26.966242+05:30
2	Velvet Touch Spa	Full-service beauty spa offering massages, facials, and body treatments.	1	456 Sunset Blvd	Los Angeles	CA	34.0922	-118.3661	+1 310-555-0202	https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800	{https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800}	4.6	89	215	t	t	10:00	19:00	\N	2026-05-23 11:46:26.966242+05:30	2026-05-23 11:46:26.966242+05:30
4	Luxe Nail Bar	Boutique nail salon offering gel, acrylic, and artistic nail designs.	1	22 Collins Ave	Miami	FL	25.7617	-80.1918	+1 305-555-0404	https://images.unsplash.com/photo-1604654894610-df63bc536371?w=800	{https://images.unsplash.com/photo-1604654894610-df63bc536371?w=800}	4.9	203	520	t	t	09:00	21:00	\N	2026-05-23 11:46:26.966242+05:30	2026-05-23 11:46:26.966242+05:30
5	Prestige Barber Co.	Old-school barbershop vibes with modern precision cuts and hot towel shaves.	1	88 King Street	Houston	TX	29.7604	-95.3698	+1 713-555-0505	https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800	{https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800}	4.7	156	410	t	t	08:00	19:00	\N	2026-05-23 11:46:26.966242+05:30	2026-05-23 11:46:26.966242+05:30
3	The Style Lab	Creative hair coloring and cutting studio for the modern trendsetter.	1	789 Michigan Ave	Chicago	IL	41.8919	-87.624	+1 312-555-0303	https://images.unsplash.com/photo-1562322140-8baeececf3df?w=800	{https://images.unsplash.com/photo-1562322140-8baeececf3df?w=800}	4.5	64	180	t	t	09:00	18:00	\N	2026-05-23 11:46:26.966242+05:30	2026-05-23 20:41:38.488+05:30
6	Glow Beauty Studio	Makeup artistry and skincare treatments by certified beauty experts.	1	33 Pike St	Seattle	WA	47.6062	-122.3321	+1 206-555-0606	https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=800	{https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=800}	4.4	48	130	t	t	10:00	18:00	\N	2026-05-23 11:46:26.966242+05:30	2026-05-23 20:41:42.037+05:30
\.


--
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.services (id, salon_id, name, description, price, duration_minutes, category, image_url, is_active, discount_percent, created_at, updated_at) FROM stdin;
1	1	Haircut & Style	Cut and blowout by a master stylist	75	60	Hair	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
2	1	Color Treatment	Full color, highlights, or balayage	150	120	Hair	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
3	1	Keratin Treatment	Smooth and frizz-free for up to 3 months	200	150	Hair	\N	t	10	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
4	1	Blowout	Professional blowout for any occasion	45	45	Hair	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
5	2	Swedish Massage	Relaxing full-body Swedish massage	110	60	Massage	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
6	2	Deep Tissue Massage	Targets deep muscle tension	130	90	Massage	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
7	2	Hydrating Facial	Deep cleanse and hydration treatment	90	60	Skincare	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
8	3	Haircut	Precision cut for all hair types	65	45	Hair	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
9	3	Balayage	Hand-painted highlights for a natural look	180	180	Hair	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
10	4	Gel Manicure	Long-lasting gel color on natural nails	45	60	Nails	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
11	4	Acrylic Full Set	Full acrylic set with any shape and length	70	90	Nails	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
12	4	Pedicure	Relaxing foot soak, exfoliate, and polish	55	75	Nails	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
13	4	Nail Art Design	Custom nail art on up to 10 nails	25	30	Nails	\N	t	15	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
14	5	Classic Haircut	Clean, precise cut for all hair types	30	30	Barber	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
15	5	Fade Cut	Taper or skin fade with clean lines	35	40	Barber	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
16	5	Hot Towel Shave	Traditional straight-razor shave experience	40	30	Barber	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
17	5	Cut & Shave Combo	Haircut plus full hot towel shave	60	60	Barber	\N	t	10	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
18	6	Full Glam Makeup	Complete makeup look for events or special occasions	120	90	Makeup	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
19	6	Bridal Makeup	Timeless bridal look with premium products	200	120	Makeup	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
20	6	Anti-Aging Facial	Firming and lifting facial treatment	95	60	Skincare	\N	t	\N	2026-05-23 11:46:26.971616+05:30	2026-05-23 11:46:26.971616+05:30
\.


--
-- Data for Name: staff; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.staff (id, salon_id, name, role, specialization, avatar_url, is_available, created_at, updated_at) FROM stdin;
1	1	Alex Rivera	Senior Stylist	Color & Balayage	\N	t	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
2	1	Jordan Lee	Stylist	Cuts & Blowouts	\N	t	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
3	1	Morgan Chen	Junior Stylist	Extensions	\N	f	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
4	2	Alex Rivera	Senior Stylist	Color & Balayage	\N	t	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
5	2	Jordan Lee	Stylist	Cuts & Blowouts	\N	t	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
6	2	Morgan Chen	Junior Stylist	Extensions	\N	f	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
7	3	Alex Rivera	Senior Stylist	Color & Balayage	\N	t	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
8	3	Jordan Lee	Stylist	Cuts & Blowouts	\N	t	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
9	3	Morgan Chen	Junior Stylist	Extensions	\N	f	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
10	4	Alex Rivera	Senior Stylist	Color & Balayage	\N	t	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
11	4	Jordan Lee	Stylist	Cuts & Blowouts	\N	t	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
12	5	Alex Rivera	Senior Stylist	Color & Balayage	\N	t	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
13	5	Jordan Lee	Stylist	Cuts & Blowouts	\N	t	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
14	6	Alex Rivera	Senior Stylist	Color & Balayage	\N	t	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
15	6	Jordan Lee	Stylist	Cuts & Blowouts	\N	t	2026-05-23 11:46:26.974555+05:30	2026-05-23 11:46:26.974555+05:30
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, name, email, password_hash, phone, avatar_url, role, created_at, updated_at) FROM stdin;
1	Salon Owner	owner@glowbook.com	$2b$10$kNkyks87LwnVECePi2alOuUG60wj7JD8k2yi8INJ8/6kNyeJA8no.	+1 555-0100	\N	owner	2026-05-23 11:46:26.961429+05:30	2026-05-23 11:46:26.961429+05:30
2	Jane Smith	jane@glowbook.com	$2b$10$kNkyks87LwnVECePi2alOuUG60wj7JD8k2yi8INJ8/6kNyeJA8no.	+1 555-0200	\N	user	2026-05-23 11:46:26.964567+05:30	2026-05-23 11:46:26.964567+05:30
3	GlowBook Administrator	admin@glowbook.com	$2b$10$c1d59MoUTQ5nGLRmMMCBlulFpGoKtYOuKYE2lEtYqSHflnj5kE0bu	+1 555-0900	\N	admin	2026-05-23 12:06:21.89008+05:30	2026-05-23 12:06:21.89008+05:30
\.


--
-- Name: admin_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.admin_logs_id_seq', 2, true);


--
-- Name: admins_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.admins_id_seq', 1, true);


--
-- Name: bookings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.bookings_id_seq', 1, false);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.categories_id_seq', 12, true);


--
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reviews_id_seq', 1, false);


--
-- Name: salons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.salons_id_seq', 6, true);


--
-- Name: services_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.services_id_seq', 20, true);


--
-- Name: staff_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.staff_id_seq', 15, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 6, true);


--
-- Name: admin_logs admin_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_logs
    ADD CONSTRAINT admin_logs_pkey PRIMARY KEY (id);


--
-- Name: admins admins_email_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_email_unique UNIQUE (email);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- Name: categories categories_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_unique UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: favorites favorites_user_id_salon_id_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_user_id_salon_id_pk PRIMARY KEY (user_id, salon_id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: salons salons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salons
    ADD CONSTRAINT salons_pkey PRIMARY KEY (id);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id);


--
-- Name: users users_email_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: admin_logs admin_logs_admin_id_admins_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_logs
    ADD CONSTRAINT admin_logs_admin_id_admins_id_fk FOREIGN KEY (admin_id) REFERENCES public.admins(id) ON DELETE CASCADE;


--
-- Name: bookings bookings_salon_id_salons_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_salon_id_salons_id_fk FOREIGN KEY (salon_id) REFERENCES public.salons(id);


--
-- Name: bookings bookings_service_id_services_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_service_id_services_id_fk FOREIGN KEY (service_id) REFERENCES public.services(id);


--
-- Name: bookings bookings_staff_id_staff_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_staff_id_staff_id_fk FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: bookings bookings_user_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_user_id_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: favorites favorites_salon_id_salons_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_salon_id_salons_id_fk FOREIGN KEY (salon_id) REFERENCES public.salons(id) ON DELETE CASCADE;


--
-- Name: favorites favorites_user_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_user_id_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_booking_id_bookings_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_booking_id_bookings_id_fk FOREIGN KEY (booking_id) REFERENCES public.bookings(id);


--
-- Name: reviews reviews_salon_id_salons_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_salon_id_salons_id_fk FOREIGN KEY (salon_id) REFERENCES public.salons(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_user_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_user_id_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: salons salons_owner_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salons
    ADD CONSTRAINT salons_owner_id_users_id_fk FOREIGN KEY (owner_id) REFERENCES public.users(id);


--
-- Name: services services_salon_id_salons_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_salon_id_salons_id_fk FOREIGN KEY (salon_id) REFERENCES public.salons(id) ON DELETE CASCADE;


--
-- Name: staff staff_salon_id_salons_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_salon_id_salons_id_fk FOREIGN KEY (salon_id) REFERENCES public.salons(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict OV8BRgR0reFeHnxyrSpUFYSfaIxdBhlbvzzQv41nMianWia4JZtovx2aZHSMtIP

