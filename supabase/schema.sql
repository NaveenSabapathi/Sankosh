-- Sankosh / Supabase PostgreSQL schema
-- Run once in a fresh Supabase project. Every user-owned table has RLS enabled.
create extension if not exists pgcrypto;

create type public.transaction_type as enum ('income','expense','transfer','investment');
create type public.record_status as enum ('active','paused','cancelled','paid','open','settled');
create type public.share_type as enum ('percentage','fixed','equal','none');
create type public.recurrence_type as enum ('weekly','monthly','quarterly','yearly','none');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text check (char_length(full_name)<=100),
  currency char(3) not null default 'INR' check (currency='INR'),
  timezone text not null default 'Asia/Kolkata',
  monthly_income numeric(14,2) not null default 0 check (monthly_income>=0),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.accounts (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80), kind text not null check (kind in ('cash','bank','credit_card','investment','loan')),
  institution text, last_four char(4), opening_balance numeric(14,2) not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.transactions (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
  account_id uuid references public.accounts(id) on delete set null, title text not null check (char_length(title) between 1 and 120),
  amount numeric(14,2) not null check (amount>=0), currency char(3) not null default 'INR' check (currency='INR'),
  type public.transaction_type not null, category text not null, transaction_date date not null,
  merchant text, notes text check (char_length(notes)<=500), source text not null default 'manual' check (source in ('manual','ai','import')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.budgets (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
  category text not null, month date not null check (date_trunc('month',month)::date=month), limit_amount numeric(14,2) not null check (limit_amount>0),
  created_at timestamptz not null default now(), unique(owner_id,category,month)
);
create table public.recurring_obligations (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
  account_id uuid references public.accounts(id) on delete set null, name text not null check (char_length(name) between 1 and 120),
  kind text not null check (kind in ('emi','rent','bill','insurance','other')), amount numeric(14,2) not null check (amount>=0),
  recurrence public.recurrence_type not null default 'monthly', next_due_date date not null, end_date date,
  auto_pay boolean not null default false, status public.record_status not null default 'active', notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), check(end_date is null or end_date>=next_due_date)
);
create table public.credit_cards (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
  account_id uuid references public.accounts(id) on delete cascade, name text not null, statement_day smallint not null check(statement_day between 1 and 31),
  due_day smallint not null check(due_day between 1 and 31), credit_limit numeric(14,2) check(credit_limit>=0), created_at timestamptz not null default now()
);
create table public.credit_card_bills (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
  credit_card_id uuid not null references public.credit_cards(id) on delete cascade, period_start date not null, period_end date not null,
  generated_on date not null, due_on date not null, total_due numeric(14,2) not null check(total_due>=0), minimum_due numeric(14,2) not null default 0 check(minimum_due>=0),
  paid_amount numeric(14,2) not null default 0 check(paid_amount>=0), status public.record_status not null default 'open', created_at timestamptz not null default now(), check(period_end>=period_start)
);
create table public.subscriptions (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120), amount numeric(14,2) not null check(amount>=0), currency char(3) not null default 'INR' check(currency='INR'),
  recurrence public.recurrence_type not null, next_billing_date date not null, category text not null default 'entertainment', auto_renew boolean not null default true,
  status public.record_status not null default 'active', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.shared_debts (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
  transaction_id uuid references public.transactions(id) on delete set null, subscription_id uuid references public.subscriptions(id) on delete set null,
  counterparty_name text not null check(char_length(counterparty_name) between 1 and 100), counterparty_phone text,
  total_amount numeric(14,2) not null check(total_amount>=0), share_type public.share_type not null,
  share_value numeric(14,2) not null check(share_value>=0), due_date date, reminder_date date,
  direction text not null default 'owed_to_me' check(direction in ('owed_to_me','i_owe')), status public.record_status not null default 'open',
  settled_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check((share_type='percentage' and share_value<=100) or share_type<>'percentage')
);
create table public.portfolios (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'Main portfolio', benchmark text default 'NIFTY 50', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.portfolio_holdings (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
  portfolio_id uuid not null references public.portfolios(id) on delete cascade, symbol text not null, exchange text not null check(exchange in ('NSE','BSE','MF','OTHER')),
  asset_type text not null check(asset_type in ('equity','etf','mutual_fund','bond','cash','other')), quantity numeric(18,6) not null check(quantity>=0),
  average_price numeric(14,4) not null check(average_price>=0), last_price numeric(14,4) check(last_price>=0), last_price_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(portfolio_id,symbol,exchange)
);
create table public.ipo_watchlist (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
  company_name text not null, issue_open date, issue_close date, price_band_low numeric(14,2), price_band_high numeric(14,2),
  source_url text, ai_summary jsonb not null default '{}'::jsonb, summary_generated_at timestamptz,
  disclaimer text not null default 'Research summary only. Not investment advice.', created_at timestamptz not null default now()
);
create table public.reminders (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
  entity_type text not null check(entity_type in ('obligation','credit_card_bill','subscription','shared_debt')),
  entity_id uuid not null, remind_at timestamptz not null, channel text not null check(channel in ('in_app','email','whatsapp')),
  message text check(char_length(message)<=500), consent_confirmed boolean not null default false, status text not null default 'scheduled' check(status in ('scheduled','sent','failed','cancelled')),
  sent_at timestamptz, created_at timestamptz not null default now()
);

create index transactions_owner_date_idx on public.transactions(owner_id,transaction_date desc);
create index obligations_owner_due_idx on public.recurring_obligations(owner_id,next_due_date) where status='active';
create index subscriptions_owner_due_idx on public.subscriptions(owner_id,next_billing_date) where status='active';
create index debts_owner_due_idx on public.shared_debts(owner_id,due_date) where status='open';
create index reminders_due_idx on public.reminders(remind_at) where status='scheduled';

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(id,full_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','')); return new; end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
create or replace function public.set_updated_at() returns trigger language plpgsql set search_path=public as $$ begin new.updated_at=now(); return new; end; $$;
create trigger profiles_updated before update on public.profiles for each row execute procedure public.set_updated_at();
create trigger accounts_updated before update on public.accounts for each row execute procedure public.set_updated_at();
create trigger transactions_updated before update on public.transactions for each row execute procedure public.set_updated_at();
create trigger obligations_updated before update on public.recurring_obligations for each row execute procedure public.set_updated_at();
create trigger subscriptions_updated before update on public.subscriptions for each row execute procedure public.set_updated_at();
create trigger debts_updated before update on public.shared_debts for each row execute procedure public.set_updated_at();
create trigger portfolios_updated before update on public.portfolios for each row execute procedure public.set_updated_at();
create trigger holdings_updated before update on public.portfolio_holdings for each row execute procedure public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.accounts enable row level security;
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;
alter table public.recurring_obligations enable row level security;
alter table public.credit_cards enable row level security;
alter table public.credit_card_bills enable row level security;
alter table public.subscriptions enable row level security;
alter table public.shared_debts enable row level security;
alter table public.portfolios enable row level security;
alter table public.portfolio_holdings enable row level security;
alter table public.ipo_watchlist enable row level security;
alter table public.reminders enable row level security;

create policy profiles_select_own on public.profiles for select using (id=auth.uid());
create policy profiles_update_own on public.profiles for update using (id=auth.uid()) with check(id=auth.uid());
do $$ declare t text; begin foreach t in array array['accounts','transactions','budgets','recurring_obligations','credit_cards','credit_card_bills','subscriptions','shared_debts','portfolios','portfolio_holdings','ipo_watchlist','reminders'] loop
  execute format('create policy %I on public.%I for select using (owner_id=auth.uid())',t||'_select_own',t);
  execute format('create policy %I on public.%I for insert with check (owner_id=auth.uid())',t||'_insert_own',t);
  execute format('create policy %I on public.%I for update using (owner_id=auth.uid()) with check (owner_id=auth.uid())',t||'_update_own',t);
  execute format('create policy %I on public.%I for delete using (owner_id=auth.uid())',t||'_delete_own',t);
end loop; end $$;

revoke all on all tables in schema public from anon;
grant usage on schema public to authenticated;
grant select,insert,update,delete on all tables in schema public to authenticated;
