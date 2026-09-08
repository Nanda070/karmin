# Live smoke (manual)

Run on a **device** with `KARMIN_LIVE_AUTH=true` (Chrome/web stays on the labeled debug mock because of CORS). Do not log passwords, OTP, or JWT.

1. Disclaimer → Login → 2FA → PIN → Today  
2. Kill app → biometric or PIN → 2FA → Today from cache  
2b. Background (JWT still in RAM) → Unlock only → Today  
3. Airplane mode → Calendar / Study / Inbox still show last saved data + cached banner  
4. Pull-to-refresh retry on the error banner  
5. Wrong password once → error, no captcha spiral  
6. Verification: **Send code again** re-POSTs login (30s cooldown), stays on OTP  
7. Sign out → Keystore empty, Login shown  
8. Exam confirm cancel does not POST  
9. Settings Theme: System / Dark / Light — all 7 screens + bottom nav restyle (cream paper in Light, ink in Dark)  
10. TalkBack / VoiceOver: tabs, Settings gear, PIN digits + backspace, OTP field, password show/hide  

Debug/web mock: any non-empty credentials, then any 6-digit OTP. Confirm the development banner is visible on Login.
