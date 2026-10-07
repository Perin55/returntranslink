-- ============================================================
-- Return Translink — Developer-Ready v1.0 Schema Migration
-- ============================================================

-- 1. Clean up old conflicting tables from previous iterations
DROP TABLE IF EXISTS public.contact_logs CASCADE;
DROP TABLE IF EXISTS public.contact_events CASCADE;
DROP TABLE IF EXISTS public.search_requests CASCADE;
DROP TABLE IF EXISTS public.truck_availability CASCADE;
DROP TABLE IF EXISTS public.return_requirements CASCADE;
DROP TABLE IF EXISTS public.return_trips CASCADE;
DROP TABLE IF EXISTS public.truck_locations CASCADE;
DROP TABLE IF EXISTS public.location_history CASCADE;
DROP TABLE IF EXISTS public.trip_status CASCADE;
DROP TABLE IF EXISTS public.truck_documents CASCADE;
DROP TABLE IF EXISTS public.documents CASCADE;
DROP TABLE IF EXISTS public.route_stops CASCADE;
DROP TABLE IF EXISTS public.routes CASCADE;
DROP TABLE IF EXISTS public.drivers CASCADE;
DROP TABLE IF EXISTS public.trucks CASCADE;
DROP TABLE IF EXISTS public.customer_locations CASCADE;
DROP TABLE IF EXISTS public.customers CASCADE;
DROP TABLE IF EXISTS public.partner_profiles CASCADE;
DROP TABLE IF EXISTS public.partners CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.favorites CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.admin_users CASCADE;
DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.support_tickets CASCADE;

-- ============================================================
-- 1. CORE USER TABLE
-- ============================================================
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT CHECK (role IN ('customer', 'partner', 'driver', 'admin')),
    full_name TEXT NOT NULL,
    mobile_number TEXT NOT NULL,
    email TEXT,
    profile_photo_url TEXT,
    language TEXT DEFAULT 'en',
    city TEXT,
    state TEXT,
    address TEXT,
    pincode TEXT,
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_profiles_role ON public.profiles(role);

-- ============================================================
-- 2. PARTNER SYSTEM
-- ============================================================
CREATE TABLE public.partners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    partner_code TEXT UNIQUE,
    owner_name TEXT NOT NULL,
    business_name TEXT,
    mobile_number TEXT NOT NULL,
    alternate_mobile TEXT,
    email TEXT,
    profile_photo_url TEXT,
    business_address TEXT,
    city TEXT,
    state TEXT,
    pincode TEXT,
    gst_number TEXT,
    pan_number TEXT,
    partner_type TEXT CHECK (partner_type IN ('individual_owner', 'fleet_owner', 'transporter', 'broker', 'company')),
    onboarding_status TEXT CHECK (onboarding_status IN ('pending', 'in_progress', 'completed', 'rejected', 'suspended')),
    verification_status TEXT CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    is_active BOOLEAN DEFAULT true,
    rating NUMERIC(3,2) DEFAULT 0,
    total_trucks INTEGER DEFAULT 0,
    total_trips INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_partners_profile_id ON public.partners(profile_id);
CREATE INDEX idx_partners_city ON public.partners(city);
CREATE INDEX idx_partners_is_active ON public.partners(is_active);
CREATE INDEX idx_partners_verification_status ON public.partners(verification_status);

-- ============================================================
-- 3. TRUCK MASTER
-- ============================================================
CREATE TABLE public.trucks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id UUID REFERENCES public.partners(id) ON DELETE CASCADE,
    truck_number TEXT UNIQUE NOT NULL,
    truck_type TEXT NOT NULL,
    body_type TEXT,
    capacity_tons NUMERIC(8,2),
    capacity_kg INTEGER NOT NULL,
    length_ft NUMERIC(5,2),
    width_ft NUMERIC(5,2),
    height_ft NUMERIC(5,2),
    vehicle_make TEXT,
    vehicle_model TEXT,
    manufacturing_year INTEGER,
    fuel_type TEXT,
    rc_number TEXT,
    rc_expiry DATE,
    insurance_expiry DATE,
    permit_expiry DATE,
    fitness_expiry DATE,
    pollution_expiry DATE,
    current_driver_id UUID,
    truck_photo_url TEXT,
    availability_status TEXT CHECK (availability_status IN ('available', 'busy', 'returning', 'offline', 'maintenance')),
    operational_status TEXT CHECK (operational_status IN ('active', 'inactive', 'maintenance', 'suspended')),
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_trucks_partner_id ON public.trucks(partner_id);
CREATE INDEX idx_trucks_availability_status ON public.trucks(availability_status);
CREATE INDEX idx_trucks_is_verified ON public.trucks(is_verified);
CREATE INDEX idx_trucks_current_driver_id ON public.trucks(current_driver_id);

-- ============================================================
-- 4. TRUCK DOCUMENTS
-- ============================================================
CREATE TABLE public.truck_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    truck_id UUID REFERENCES public.trucks(id) ON DELETE CASCADE,
    document_type TEXT,
    document_number TEXT,
    document_url TEXT,
    issue_date DATE,
    expiry_date DATE,
    verification_status TEXT CHECK (verification_status IN ('pending', 'verified', 'rejected', 'expired')),
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_truck_documents_truck_id ON public.truck_documents(truck_id);
CREATE INDEX idx_truck_documents_type ON public.truck_documents(document_type);
CREATE INDEX idx_truck_documents_expiry ON public.truck_documents(expiry_date);

-- ============================================================
-- 5. DRIVERS
-- ============================================================
CREATE TABLE public.drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id UUID REFERENCES public.partners(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    driver_name TEXT,
    mobile_number TEXT,
    alternate_mobile TEXT,
    photo_url TEXT,
    license_number TEXT,
    license_type TEXT,
    license_expiry DATE,
    experience_years NUMERIC,
    address TEXT,
    city TEXT,
    state TEXT,
    is_available BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    current_truck_id UUID REFERENCES public.trucks(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_drivers_partner_id ON public.drivers(partner_id);
CREATE INDEX idx_drivers_current_truck_id ON public.drivers(current_truck_id);

-- ============================================================
-- 6. ROUTES
-- ============================================================
CREATE TABLE public.routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id UUID REFERENCES public.partners(id) ON DELETE CASCADE,
    truck_id UUID REFERENCES public.trucks(id) ON DELETE CASCADE,
    route_name TEXT,
    origin_city TEXT,
    origin_state TEXT,
    origin_latitude NUMERIC,
    origin_longitude NUMERIC,
    destination_city TEXT,
    destination_state TEXT,
    destination_latitude NUMERIC,
    destination_longitude NUMERIC,
    distance_km NUMERIC,
    estimated_duration_minutes INTEGER,
    route_type TEXT CHECK (route_type IN ('regular', 'return', 'one_way')),
    frequency TEXT CHECK (frequency IN ('daily', 'weekly', 'occasionally', 'one_time')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_routes_origin_city ON public.routes(origin_city);
CREATE INDEX idx_routes_destination_city ON public.routes(destination_city);

-- ============================================================
-- 7. ROUTE STOPS
-- ============================================================
CREATE TABLE public.route_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID REFERENCES public.routes(id) ON DELETE CASCADE,
    stop_order INTEGER,
    location_name TEXT,
    city TEXT,
    state TEXT,
    latitude NUMERIC,
    longitude NUMERIC,
    expected_arrival_time TIME,
    expected_departure_time TIME,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(route_id, stop_order)
);
CREATE INDEX idx_route_stops_route_id ON public.route_stops(route_id);

-- ============================================================
-- 8. DAILY TRUCK AVAILABILITY (CUSTOMER-FACING TRUCKS)
-- ============================================================
CREATE TABLE public.truck_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    truck_id UUID REFERENCES public.trucks(id) ON DELETE CASCADE,
    partner_id UUID REFERENCES public.partners(id) ON DELETE CASCADE,
    route_id UUID REFERENCES public.routes(id) ON DELETE SET NULL,
    available_date DATE,
    available_from_time TIME,
    available_until_time TIME,
    origin_location TEXT,
    origin_city TEXT,
    origin_state TEXT,
    origin_latitude NUMERIC,
    origin_longitude NUMERIC,
    destination_location TEXT,
    destination_city TEXT,
    destination_state TEXT,
    destination_latitude NUMERIC,
    destination_longitude NUMERIC,
    total_capacity_kg INTEGER,
    available_capacity_kg INTEGER,
    status TEXT CHECK (status IN ('available', 'partially_available', 'full', 'unavailable', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CHECK (available_capacity_kg >= 0),
    CHECK (available_capacity_kg <= total_capacity_kg)
);
CREATE INDEX idx_availability_search ON public.truck_availability(available_date, origin_city, destination_city, status);

-- ============================================================
-- 9. TRUCK LOCATIONS
-- ============================================================
CREATE TABLE public.truck_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    truck_id UUID UNIQUE REFERENCES public.trucks(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
    latitude NUMERIC,
    longitude NUMERIC,
    location_name TEXT,
    city TEXT,
    state TEXT,
    speed_kmph NUMERIC,
    heading NUMERIC,
    accuracy NUMERIC,
    battery_level NUMERIC,
    location_source TEXT,
    is_tracking_enabled BOOLEAN,
    recorded_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 10. LOCATION HISTORY
-- ============================================================
CREATE TABLE public.location_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    truck_id UUID REFERENCES public.trucks(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
    latitude NUMERIC,
    longitude NUMERIC,
    location_name TEXT,
    city TEXT,
    state TEXT,
    speed_kmph NUMERIC,
    heading NUMERIC,
    accuracy NUMERIC,
    battery_level NUMERIC,
    recorded_at TIMESTAMPTZ
);
CREATE INDEX idx_location_history_truck ON public.location_history(truck_id, recorded_at);

-- ============================================================
-- 11. TRIP STATUS
-- ============================================================
DROP TYPE IF EXISTS public.trip_status CASCADE;

CREATE TABLE public.trip_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    truck_id UUID REFERENCES public.trucks(id) ON DELETE CASCADE,
    partner_id UUID REFERENCES public.partners(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
    status TEXT CHECK (status IN ('not_started', 'loading', 'started', 'in_transit', 'returning_empty', 'reached_destination', 'available_for_return', 'completed', 'cancelled')),
    origin_city TEXT,
    destination_city TEXT,
    started_at TIMESTAMPTZ,
    estimated_arrival_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    current_latitude NUMERIC,
    current_longitude NUMERIC,
    current_location TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 12. CUSTOMERS
-- ============================================================
CREATE TABLE public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    customer_type TEXT CHECK (customer_type IN ('individual', 'business', 'manufacturer', 'trader', 'broker', 'transporter', 'other')),
    company_name TEXT,
    gst_number TEXT,
    business_address TEXT,
    city TEXT,
    state TEXT,
    pincode TEXT,
    preferred_language TEXT,
    total_searches INTEGER DEFAULT 0,
    total_contacts INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_customers_profile_id ON public.customers(profile_id);

-- ============================================================
-- 13. CUSTOMER LOCATIONS
-- ============================================================
CREATE TABLE public.customer_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
    location_name TEXT,
    location_type TEXT CHECK (location_type IN ('home', 'office', 'factory', 'warehouse', 'pickup', 'drop', 'other')),
    contact_person TEXT,
    contact_number TEXT,
    address_line TEXT,
    landmark TEXT,
    city TEXT,
    state TEXT,
    pincode TEXT,
    latitude NUMERIC,
    longitude NUMERIC,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 14. SEARCH REQUESTS
-- ============================================================
CREATE TABLE public.search_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
    pickup_location TEXT,
    pickup_city TEXT,
    pickup_state TEXT,
    pickup_latitude NUMERIC,
    pickup_longitude NUMERIC,
    drop_location TEXT,
    drop_city TEXT,
    drop_state TEXT,
    drop_latitude NUMERIC,
    drop_longitude NUMERIC,
    required_date DATE,
    required_time TIME,
    material_type TEXT,
    material_description TEXT,
    required_capacity_kg INTEGER,
    required_truck_type TEXT,
    required_body_type TEXT,
    number_of_packages INTEGER,
    special_requirements TEXT,
    search_status TEXT CHECK (search_status IN ('active', 'completed', 'expired', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_searches ON public.search_requests(required_date, pickup_city, drop_city, search_status);

-- ============================================================
-- 15. CONTACT LOGS
-- ============================================================
CREATE TABLE public.contact_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
    partner_id UUID REFERENCES public.partners(id) ON DELETE CASCADE,
    truck_id UUID REFERENCES public.trucks(id) ON DELETE CASCADE,
    search_request_id UUID REFERENCES public.search_requests(id) ON DELETE SET NULL,
    contact_type TEXT CHECK (contact_type IN ('call', 'whatsapp', 'chat', 'view_phone', 'view_whatsapp')),
    contacted_at TIMESTAMPTZ DEFAULT now(),
    customer_latitude NUMERIC,
    customer_longitude NUMERIC,
    source TEXT,
    device_type TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 16. NOTIFICATIONS
-- ============================================================
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    notification_type TEXT,
    reference_type TEXT,
    reference_id UUID,
    is_read BOOLEAN DEFAULT false,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 17. FAVORITES
-- ============================================================
CREATE TABLE public.favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
    truck_id UUID REFERENCES public.trucks(id) ON DELETE CASCADE,
    partner_id UUID REFERENCES public.partners(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(customer_id, truck_id)
);

-- ============================================================
-- 18. REPORTS
-- ============================================================
CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
    partner_id UUID REFERENCES public.partners(id) ON DELETE SET NULL,
    truck_id UUID REFERENCES public.trucks(id) ON DELETE SET NULL,
    reason TEXT CHECK (reason IN ('wrong_information', 'fake_vehicle', 'wrong_location', 'owner_not_responding', 'fraud', 'other')),
    description TEXT,
    status TEXT CHECK (status IN ('open', 'under_review', 'resolved', 'rejected')),
    admin_note TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    resolved_at TIMESTAMPTZ
);

-- ============================================================
-- 19. ADMIN USERS
-- ============================================================
CREATE TABLE public.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT CHECK (role IN ('super_admin', 'operations', 'support', 'verification')),
    permissions JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 20. AUDIT LOGS
-- ============================================================
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID NOT NULL,
    old_data JSONB,
    new_data JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 21. SUPPORT TICKETS
-- ============================================================
CREATE TABLE public.support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    ticket_number TEXT UNIQUE NOT NULL,
    category TEXT,
    subject TEXT,
    description TEXT,
    priority TEXT CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status TEXT CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    assigned_to UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    resolution TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    resolved_at TIMESTAMPTZ
);

-- ============================================================
-- FINAL RLS & SECURITY
-- ============================================================
-- To be implemented by Developer as per spec
