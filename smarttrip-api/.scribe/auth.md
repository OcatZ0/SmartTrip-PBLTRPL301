# Authenticating requests

To authenticate requests, include an **`Authorization`** header with the value **`"Bearer {YOUR_SANCTUM_TOKEN}"`**.

All authenticated endpoints are marked with a `requires authentication` badge in the documentation below.

Token didapat dari response <code>POST /auth/login</code>, <code>POST /auth/google</code>, atau setelah klik link verifikasi registrasi - berupa Sanctum personal access token (bukan JWT), dipakai sebagai <code>Authorization: Bearer {token}</code>.
