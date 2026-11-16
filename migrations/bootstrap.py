"""First-run setup for Helicone on Railway. Safe to run on every deploy.

1. Sets the password of ClickHouse's read-only `hql_user` (Helicone's migrations
   create it without one) from CLICKHOUSE_HQL_PASSWORD.
2. Creates the first admin when HELICONE_ADMIN_EMAIL is set and no user has that
   email: a verified Better Auth user with an email/password login, an
   organization and an owner membership. Helicone's Docker guide does the same
   by hand with SQL, because self-hosted Helicone sends no verification email.

Password hash format of Better Auth 1.x: "<salt hex>:<scrypt key hex>",
scrypt(N=16384, r=16, p=1, dkLen=64) over the NFKC password, salted with the
salt's hex string.
"""
import hashlib
import os
import secrets
import string
import sys
import unicodedata
import urllib.parse
import urllib.request

import psycopg

ALNUM = string.ascii_letters + string.digits


def log(msg):
    print(f"railway: {msg}", flush=True)


def set_hql_password():
    pw = os.environ.get("CLICKHOUSE_HQL_PASSWORD", "")
    if not pw:
        log("CLICKHOUSE_HQL_PASSWORD not set, hql_user left unchanged")
        return
    if any(c not in ALNUM for c in pw):
        sys.exit("railway: CLICKHOUSE_HQL_PASSWORD must be letters and digits only")
    query = f"ALTER USER IF EXISTS hql_user IDENTIFIED WITH sha256_password BY '{pw}'"
    req = urllib.request.Request(
        os.environ["CLICKHOUSE_HOST"].rstrip("/") + "/?" + urllib.parse.urlencode({"query": query}),
        method="POST",
        headers={
            "X-ClickHouse-User": os.environ.get("CLICKHOUSE_USER", "default"),
            "X-ClickHouse-Key": os.environ.get("CLICKHOUSE_PASSWORD", ""),
        },
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        r.read()
    log("hql_user password set")


def better_auth_hash(password):
    salt = secrets.token_hex(16)
    key = hashlib.scrypt(
        unicodedata.normalize("NFKC", password).encode(),
        salt=salt.encode(), n=16384, r=16, p=1, dklen=64, maxmem=64 * 1024 * 1024,
    )
    return f"{salt}:{key.hex()}"


def rid(n=32):
    return "".join(secrets.choice(ALNUM) for _ in range(n))


def bootstrap_admin():
    email = os.environ.get("HELICONE_ADMIN_EMAIL", "").strip().lower()
    password = os.environ.get("HELICONE_ADMIN_PASSWORD", "")
    if not email:
        log("HELICONE_ADMIN_EMAIL not set, no admin created")
        return
    if len(password) < 8:
        sys.exit("railway: HELICONE_ADMIN_PASSWORD needs at least 8 characters")
    org_name = os.environ.get("HELICONE_ORG_NAME", "My Organization")

    with psycopg.connect(os.environ["DATABASE_URL"]) as conn, conn.cursor() as cur:
        cur.execute('SELECT 1 FROM public."user" WHERE lower(email) = %s', (email,))
        if cur.fetchone():
            log(f"admin {email} already exists")
            return
        uid = rid()
        cur.execute(
            'INSERT INTO public."user" (id, name, email, "emailVerified", "createdAt", "updatedAt") '
            "VALUES (%s, %s, %s, true, now(), now()) RETURNING auth_user_id",
            (uid, "Admin", email),
        )
        auth_uid = cur.fetchone()[0]
        cur.execute(
            'INSERT INTO public.account (id, "accountId", "providerId", "userId", password, "createdAt", "updatedAt") '
            "VALUES (%s, %s, 'credential', %s, %s, now(), now())",
            (rid(), uid, uid, better_auth_hash(password)),
        )
        # A database trigger may already have made a personal organization.
        cur.execute("SELECT organization FROM public.organization_member WHERE member = %s LIMIT 1", (auth_uid,))
        row = cur.fetchone()
        if row:
            org_id = row[0]
            cur.execute(
                'UPDATE public.organization_member SET "user" = %s WHERE member = %s AND organization = %s',
                (uid, auth_uid, org_id),
            )
        else:
            cur.execute(
                "INSERT INTO public.organization (name, is_personal, owner) VALUES (%s, true, %s) RETURNING id",
                (org_name, auth_uid),
            )
            org_id = cur.fetchone()[0]
            cur.execute(
                'INSERT INTO public.organization_member ("user", member, organization, org_role) '
                "VALUES (%s, %s, %s, 'owner')",
                (uid, auth_uid, org_id),
            )
        cur.execute(
            "UPDATE public.organization SET name = %s, has_onboarded = true WHERE id = %s",
            (org_name, org_id),
        )
        conn.commit()
    log(f"created admin {email} (organization '{org_name}')")


if __name__ == "__main__":
    set_hql_password()
    bootstrap_admin()
