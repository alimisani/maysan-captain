const https = require('https');

const sql = `
CREATE TABLE IF NOT EXISTS public.profiles (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  avatar_url TEXT,
  rating NUMERIC(3,2) DEFAULT 5.00,
  total_trips INTEGER DEFAULT 0,
  is_blocked BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  driver_name TEXT,
  vehicle_type TEXT NOT NULL,
  plate_number TEXT,
  model TEXT,
  color TEXT,
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.rides_and_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number TEXT,
  customer_id TEXT NOT NULL,
  customer_name TEXT,
  customer_phone TEXT,
  driver_id TEXT,
  driver_name TEXT,
  driver_phone TEXT,
  driver_rating NUMERIC(3,2) DEFAULT 5.00,
  vehicle_info TEXT,
  type TEXT NOT NULL DEFAULT 'ride',
  pickup_address TEXT NOT NULL,
  pickup_lat NUMERIC NOT NULL,
  pickup_lng NUMERIC NOT NULL,
  dropoff_address TEXT NOT NULL,
  dropoff_lat NUMERIC NOT NULL,
  dropoff_lng NUMERIC NOT NULL,
  distance_km NUMERIC DEFAULT 0,
  initial_fare NUMERIC NOT NULL DEFAULT 3000,
  final_fare NUMERIC NOT NULL DEFAULT 3000,
  status TEXT NOT NULL DEFAULT 'pending',
  notes TEXT,
  package_details TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id UUID,
  customer_id TEXT,
  customer_name TEXT,
  driver_id TEXT,
  rating NUMERIC(3,2) NOT NULL,
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO public.profiles (id, name, email, phone, password_hash, role, rating, total_trips)
VALUES ('admin-maysan-tech', 'ميسان تك', 'maysan.tech1@gmail.com', '07832197406', '33221144', 'admin', 5.00, 100)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  phone = EXCLUDED.phone,
  password_hash = EXCLUDED.password_hash,
  role = 'admin';

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides_and_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all on profiles') THEN
    CREATE POLICY "Allow all on profiles" ON public.profiles FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all on vehicles') THEN
    CREATE POLICY "Allow all on vehicles" ON public.vehicles FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all on rides_and_deliveries') THEN
    CREATE POLICY "Allow all on rides_and_deliveries" ON public.rides_and_deliveries FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all on reviews') THEN
    CREATE POLICY "Allow all on reviews" ON public.reviews FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all on app_settings') THEN
    CREATE POLICY "Allow all on app_settings" ON public.app_settings FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;
`;

const data = JSON.stringify({ query: sql });

const options = {
  hostname: 'api.supabase.com',
  port: 443,
  path: '/v1/projects/aksvjsuniudzxumbaiph/database/query',
  method: 'POST',
  headers: {
    'Authorization': 'Bearer sbp_d12d24ad56fa314b4a4373495abcf0452a0f4074',
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data)
  }
};

const req = https.request(options, (res) => {
  let body = '';
  res.on('data', (d) => body += d);
  res.on('end', () => {
    console.log('Status Code:', res.statusCode);
    console.log('Response:', body);
  });
});

req.on('error', (e) => {
  console.error(e);
});

req.write(data);
req.end();
