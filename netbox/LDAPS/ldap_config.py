#ldap_config.py is created in the same folder as configuration.py
import ldap
from django_auth_ldap.config import LDAPSearch, NestedGroupOfNamesType

# Server URI
AUTH_LDAP_SERVER_URI = "ldaps://dc01.domain.local"

# The following may be needed if you are binding to Active Directory.
AUTH_LDAP_CONNECTION_OPTIONS = {
    ldap.OPT_REFERRALS: 0
}

# Set the DN and password for the NetBox service account.
AUTH_LDAP_BIND_DN = "CN=LDAPS-SA,OU=Users,DC=domain,DC=local"
AUTH_LDAP_BIND_PASSWORD = "Password"

# Include this setting if you want to ignore certificate errors. This might be needed to accept a self-signed cert.
# Note that this is a NetBox-specific setting which sets:
#     ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_NEVER)
LDAP_IGNORE_CERT_ERRORS = False

# Include this setting if you want to validate the LDAP server certificates against a CA certificate directory on your server
# Note that this is a NetBox-specific setting which sets:
#     ldap.set_option(ldap.OPT_X_TLS_CACERTDIR, LDAP_CA_CERT_DIR)
LDAP_CA_CERT_DIR = '/usr/local/share/ca-certificates/'

# Include this setting if you want to validate the LDAP server certificates against your own CA.
# Note that this is a NetBox-specific setting which sets:
#     ldap.set_option(ldap.OPT_X_TLS_CACERTFILE, LDAP_CA_CERT_FILE)
LDAP_CA_CERT_FILE = '/usr/local/share/ca-certificates/root-ca.crt'

# This search matches users with the sAMAccountName equal to the provided username. This is required if the user's
# username is not in their DN (Active Directory).
AUTH_LDAP_USER_SEARCH = LDAPSearch(
    "OU=Users,DC=domain,DC=local",
    ldap.SCOPE_SUBTREE,
    "(|(userPrincipalName=%(user)s)(sAMAccountName=%(user)s))"
)

# If a user's DN is producible from their username, we don't need to search.
AUTH_LDAP_USER_DN_TEMPLATE = None

# You can map user attributes to Django attributes as so.
AUTH_LDAP_USER_ATTR_MAP = {
    "username": "sAMAccountName",
    "email": "mail",
    "first_name": "givenName",
    "last_name": "sn",
}

AUTH_LDAP_USER_QUERY_FIELD = "username"

# This search ought to return all groups to which the user belongs. django_auth_ldap uses this to determine group
# hierarchy.
AUTH_LDAP_GROUP_SEARCH = LDAPSearch(
    "CN=Netbox Users,OU=Users,DC=domain,DC=local",
    ldap.SCOPE_SUBTREE,
    "(objectClass=group)"
)
AUTH_LDAP_GROUP_TYPE = NestedGroupOfNamesType()

# Define a group required to login.
AUTH_LDAP_REQUIRE_GROUP = "CN=Netbox Users,OU=Users,DC=domain,DC=local"

# Mirror LDAP group assignments.
AUTH_LDAP_MIRROR_GROUPS = True

# Define special user types using groups. Exercise great caution when assigning superuser status.
AUTH_LDAP_USER_FLAGS_BY_GROUP = {
    "is_active": "CN=Netbox Users,OU=Users,DC=domain,DC=local",
    "is_staff": "CN=Netbox Users,OU=Users,DC=domain,DC=local",
    "is_superuser": "CN=Netbox Users,OU=Users,DC=domain,DC=local"
}

# For more granular permissions, we can map LDAP groups to Django groups.
AUTH_LDAP_FIND_GROUP_PERMS = True

# Cache groups for one hour to reduce LDAP traffic
AUTH_LDAP_CACHE_TIMEOUT = 3600
AUTH_LDAP_ALWAYS_UPDATE_USER = True
LDAP_AUTH_USE_TLS = True # Ensure TLS is enabled
#LDAP_AUTH_TLS_VERIFY_CERTIFICATES = False
