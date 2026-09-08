# Data layer

Stage 2 uses a **JSON cache** (`CacheStore` / SharedPreferences key `karmin.cache.student.v1`) and `StudentRepository` (stale-while-revalidate, 5 minutes).

Isar collections were the plan; they are deferred because codegen is brittle on the current SDK. Hive/Isar can replace the JSON blob later without changing DTOs.

Wiped on Sign out. Never stores password, OTP, or JWT.
