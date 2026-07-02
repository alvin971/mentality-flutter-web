-- Schéma Supabase du système de déblocage des résultats par paliers.
-- À exécuter dans l'éditeur SQL Supabase (une fois). Le worker referral y
-- accède via PostgREST avec la clé service_role (jamais exposée au client).

-- Un enregistrement par testeur ayant terminé son test complet.
create table if not exists unlock_progress (
  account          text primary key,                 -- SHA256(nonce)[:32] dérivé du token signé
  referral_code    text unique not null,             -- code court du lien d'invitation
  stage            smallint not null default 1,      -- 1=inviter, 2=attente, 3=instagram, 4=débloqué
  instagram_handle text,
  instagram_submitted_at timestamptz,
  instagram_verified boolean,                        -- contrôle manuel admin (null = non contrôlé)
  unlocked_at      timestamptz,
  created_at       timestamptz not null default now()
);

-- Filleuls : un token filleul ne peut valider qu'UN parrain, une seule fois.
create table if not exists referrals (
  id                bigint generated always as identity primary key,
  referrer_code     text not null references unlock_progress(referral_code),
  referee_account   text not null unique,
  clicked_at        timestamptz not null default now(),
  test_completed_at timestamptz                      -- null tant que le test filleul n'est pas fini
);

create index if not exists referrals_referrer_idx on referrals (referrer_code);

-- RLS activée sans policy : seul le service_role (worker) peut lire/écrire.
alter table unlock_progress enable row level security;
alter table referrals enable row level security;
