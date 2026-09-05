# OmniRoute Installation Guide

این مخزن شامل اسکریپت‌ها و فایل‌های لازم برای نصب **OmniRoute** روی VPS هست.

## ⚠️ نکته مهم

این نصب **هیچ اختلالی** در سرویس‌های موجود روی VPS ایجاد نمی‌کنه:
- از پورت `20128` استفاده می‌کنه
- کانتینر Docker ایزوله اجرا می‌شه
- سرویس‌های systemd موجود دست‌نخورده می‌مونن

## VPS جدید

**IP:** `89.251.8.32`

## روش نصب

### گزینه ۱: اجرای خودکار با اسکریپت

```bash
curl -fsSL https://raw.githubusercontent.com/Reymond-Reddington/omniroute-setup/main/install.sh -o install.sh
chmod +x install.sh
sudo ./install.sh
```

### گزینه ۲: Docker Compose

```bash
git clone https://github.com/Reymond-Reddington/omniroute-setup.git
cd omniroute-setup
cp .env.example .env
nano .env  # ویرایش پسورد
docker compose up -d
```

## دسترسی پس از نصب

- **داشبورد:** `http://89.251.8.32:20128/dashboard`
- **API Endpoint:** `http://89.251.8.32:20128/v1/chat/completions`

### پسورد پیش‌فرض

```
ChangeThisPassword123!
```

⚠️ **حتماً بعد از اولین ورود پسورد رو تغییر بده!**

## مدیریت سرویس

```bash
docker logs -f omniroute      # مشاهده لاگ‌ها
docker stop omniroute         # توقف
docker restart omniroute      # شروع مجدد
```

## منابع

- [مخزن اصلی OmniRoute](https://github.com/diegosouzapw/OmniRoute)
- [مستندات رسمی](https://github.com/diegosouzapw/OmniRoute/wiki)
