-- EDUNOVA: jalankan di Supabase SQL Editor.
create extension if not exists pgcrypto;

create type public.app_role as enum ('admin','guru','murid','ibu_bapa');

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default 'Pengguna EDUNOVA',
 role public.app_role not null default 'murid',
 year_level int check (year_level between 4 and 6) default 4,
 created_at timestamptz not null default now()
);
create table public.classes (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 year_level int not null check (year_level between 4 and 6),
 teacher_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now()
);
create table public.class_members (
 class_id uuid not null references public.classes(id) on delete cascade,
 student_id uuid not null references public.profiles(id) on delete cascade,
 primary key(class_id,student_id)
);
create table public.parent_links (
 parent_id uuid not null references public.profiles(id) on delete cascade,
 child_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(parent_id,child_id),
 check(parent_id <> child_id)
);
create table public.learning_content (
 id uuid primary key default gen_random_uuid(),
 year_level int not null check(year_level between 4 and 6),
 topic text not null,
 content_type text not null check(content_type in ('nota','soalan')),
 title text not null,
 body jsonb not null default '{}'::jsonb,
 published boolean not null default false,
 created_by uuid references public.profiles(id),
 created_at timestamptz not null default now()
);
create table public.attempts (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.profiles(id) on delete cascade,
 content_id uuid references public.learning_content(id) on delete set null,
 topic text not null,
 year_level int not null check(year_level between 4 and 6),
 score numeric(5,2) not null default 0 check(score between 0 and 100),
 correct_count int not null default 0 check(correct_count >= 0),
 total_count int not null default 0 check(total_count >= correct_count),
 duration_seconds int check(duration_seconds is null or duration_seconds >= 0),
 created_at timestamptz not null default now()
);
create table public.wallets (
 student_id uuid primary key references public.profiles(id) on delete cascade,
 coins bigint not null default 50 check(coins >= 0),
 xp bigint not null default 0 check(xp >= 0),
 updated_at timestamptz not null default now()
);
create table public.rewards (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.profiles(id) on delete cascade,
 reward_type text not null,
 reward_code text not null,
 unlocked_at timestamptz not null default now(),
 unique(student_id,reward_code)
);
create table public.audit_logs (
 id bigint generated always as identity primary key,
 actor_id uuid references public.profiles(id) on delete set null,
 action text not null,
 target_type text,
 target_id text,
 details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);

-- Profil diwujudkan secara automatik; peranan awam sentiasa murid.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id,full_name,role,year_level)
 values(new.id, coalesce(new.raw_user_meta_data->>'full_name','Pengguna EDUNOVA'),
        'murid', coalesce(nullif(new.raw_user_meta_data->>'year_level','')::int,4))
 on conflict(id) do nothing;
 insert into public.wallets(student_id) values(new.id) on conflict(student_id) do nothing;
 return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users
 for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin');
$$;
create or replace function public.is_teacher_of_student(student uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.classes c join public.class_members cm on cm.class_id=c.id
 where c.teacher_id=auth.uid() and cm.student_id=student);
$$;
create or replace function public.is_parent_of_student(student uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.parent_links pl where pl.parent_id=auth.uid() and pl.child_id=student);
$$;

alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.class_members enable row level security;
alter table public.parent_links enable row level security;
alter table public.learning_content enable row level security;
alter table public.attempts enable row level security;
alter table public.wallets enable row level security;
alter table public.rewards enable row level security;
alter table public.audit_logs enable row level security;

create policy "profiles view self admin teacher parent" on public.profiles for select to authenticated
 using(id=auth.uid() or public.is_admin() or public.is_teacher_of_student(id) or public.is_parent_of_student(id));
create policy "profiles update self safe fields" on public.profiles for update to authenticated
 using(id=auth.uid() and role='murid') with check(id=auth.uid() and role='murid');
create policy "admin manage profiles" on public.profiles for all to authenticated
 using(public.is_admin()) with check(public.is_admin());

create policy "teacher sees assigned classes" on public.classes for select to authenticated
 using(teacher_id=auth.uid() or public.is_admin());
create policy "admin and teacher manage classes" on public.classes for all to authenticated
 using(teacher_id=auth.uid() or public.is_admin()) with check(teacher_id=auth.uid() or public.is_admin());
create policy "class members visible to assigned teacher/student" on public.class_members for select to authenticated
 using(student_id=auth.uid() or public.is_teacher_of_student(student_id) or public.is_admin());
create policy "admin teacher manage class members" on public.class_members for all to authenticated
 using(public.is_admin() or exists(select 1 from public.classes c where c.id=class_id and c.teacher_id=auth.uid()))
 with check(public.is_admin() or exists(select 1 from public.classes c where c.id=class_id and c.teacher_id=auth.uid()));
create policy "parent links visible to linked parties" on public.parent_links for select to authenticated
 using(parent_id=auth.uid() or child_id=auth.uid() or public.is_admin());
create policy "admin manages parent links" on public.parent_links for all to authenticated
 using(public.is_admin()) with check(public.is_admin());

create policy "published content readable" on public.learning_content for select to authenticated
 using(published=true or public.is_admin() or created_by=auth.uid());
create policy "teacher admin manage content" on public.learning_content for all to authenticated
 using(public.is_admin() or (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='guru') and created_by=auth.uid()))
 with check(public.is_admin() or (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='guru') and created_by=auth.uid()));

create policy "student and authorized adults read attempts" on public.attempts for select to authenticated
 using(student_id=auth.uid() or public.is_admin() or public.is_teacher_of_student(student_id) or public.is_parent_of_student(student_id));
create policy "student inserts own attempts" on public.attempts for insert to authenticated
 with check(student_id=auth.uid());
create policy "admin reads wallet" on public.wallets for select to authenticated
 using(student_id=auth.uid() or public.is_admin() or public.is_teacher_of_student(student_id) or public.is_parent_of_student(student_id));
create policy "student rewards visible" on public.rewards for select to authenticated
 using(student_id=auth.uid() or public.is_admin() or public.is_teacher_of_student(student_id) or public.is_parent_of_student(student_id));
create policy "audit admin only" on public.audit_logs for select to authenticated using(public.is_admin());

-- Jangan beri kebenaran UPDATE wallet atau pengurusan auth kepada client.
-- Pemberian syiling/XP mesti melalui fungsi pelayan yang mengesahkan markah.
