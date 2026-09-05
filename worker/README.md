# OmniRoute Worker Proxy

Cloudflare Worker که به‌عنوان proxy برای OmniRoute روی VPS عمل می‌کنه.

## پیش‌نیازها

```bash
npm install -g wrangler
wrangler login
```

## نصب و راه‌اندازی

```bash
cd worker
npm install
```

## کانفیگ

فایل `wrangler.toml` رو ویرایش کن:

```toml
[vars]
OMNIRoute_URL = "http://185.110.190.166:20128"
# API_KEY = "your-api-key"  # اختیاری
```

## Deploy

```bash
npm run deploy
```

## تست محلی

```bash
npm run dev
```

## دسترسی

بعد از deploy، Worker در دسترسه:
```
https://omniroute-proxy.<your-subdomain>.workers.dev
```

## مثال استفاده

```bash
# Chat completions
curl https://omniroute-proxy.<subdomain>.workers.dev/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"auto","messages":[{"role":"user","content":"Hello!"}]}'

# Dashboard
# https://omniroute-proxy.<subdomain>.workers.dev/dashboard
```

## اضافه کردن دامنه سفارشی (اختیاری)

1. در داشبورد Cloudflare Workers → Custom Domains
2. دامنه مورد نظر رو اضافه کن
3. یا در `wrangler.toml`:

```toml
[[routes]]
pattern = "llms.yourdomain.com/*"
zone_name = "yourdomain.com"
```

## لاگ‌ها

```bash
npm run tail
```
