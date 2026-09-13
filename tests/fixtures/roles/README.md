# Fixture stand-in for a site repo's service-roles dir (tier 2).
# site-valid.yml declares `local_roles: roles/`; the resolver refuses a
# declared-but-missing dir, so this directory exists to prove the happy
# path. Real service roles live in the SITE repo, never here.
