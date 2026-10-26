#!/usr/bin/env bash
# استفاده: bash setup.sh [نام-پوشه]  — کل پروژه را می‌سازد
set -euo pipefail
APP="${1:-golrokh-shop}"
mkdir -p "$APP" && cd "$APP"

mkdir -p "$(dirname ".devcontainer/devcontainer.json")"
cat > '.devcontainer/devcontainer.json' <<'__EOF_FILE__'
{
  "name": "golrokh-shop",
  "image": "mcr.microsoft.com/devcontainers/typescript-node:20",
  "features": { "ghcr.io/devcontainers/features/docker-in-docker:2": {} },
  "postCreateCommand": "cp -n .env.example .env; npm install && docker compose up -d --wait && npm run migrate && npm run seed",
  "forwardPorts": [3000],
  "portsAttributes": { "3000": { "label": "Shop", "onAutoForward": "openPreview" } }
}
__EOF_FILE__
mkdir -p "$(dirname ".env.example")"
cat > '.env.example' <<'__EOF_FILE__'
DATABASE_URL=postgres://shop:shop@localhost:5432/shop
JWT_SECRET=change-me-before-going-live
PORT=3000
# در سایت واقعی (HTTPS) حتماً true شود
COOKIE_SECURE=false
SEED_ADMIN_EMAIL=admin@example.com
SEED_ADMIN_PASSWORD=Admin12345
__EOF_FILE__
mkdir -p "$(dirname ".github/workflows/ci.yml")"
cat > '.github/workflows/ci.yml' <<'__EOF_FILE__'
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: shop
          POSTGRES_PASSWORD: shop
          POSTGRES_DB: shop
        ports: ["5432:5432"]
        options: >-
          --health-cmd "pg_isready -U shop" --health-interval 5s
          --health-timeout 5s --health-retries 10
    env:
      DATABASE_URL: postgres://shop:shop@localhost:5432/shop
      JWT_SECRET: ci-secret
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm install
      - run: npm run typecheck
      - run: npm run migrate
      - run: npm run seed
      - run: npm test
__EOF_FILE__
mkdir -p "$(dirname ".gitignore")"
cat > '.gitignore' <<'__EOF_FILE__'
node_modules
.env
uploads/*
!uploads/.gitkeep
*.log
__EOF_FILE__
mkdir -p "$(dirname "README.md")"
cat > 'README.md' <<'__EOF_FILE__'
# گل‌رخ — فروشگاه لوازم آرایشی و بهداشتی با همکاری در فروش (۳ سطح)

فروشگاه کامل با: کاتالوگ محصول (عکس، توضیحات، روش مصرف، ترکیبات، قیمت به افغانی)، سبد خرید و سفارش،
سیستم پورسانت ۳ سطحی (فقط از خرید قطعی محصول)، پنل همکار، و پنل مدیریت (محصولات + آپلود عکس، سفارش‌ها، پورسانت، برداشت، نرخ‌ها، ضدتقلب، لاگ).

**پشته:** Node.js + Express + TypeScript (tsx) + PostgreSQL + فرانت‌اند ساده (بدون build).

## اجرا روی GitHub Codespaces (بدون نصب روی کامپیوتر خودتان)
۱. پروژه را در یک مخزن GitHub بگذارید. ۲. دکمه سبز **Code → Codespaces → Create codespace** را بزنید.
۳. صبر کنید تا نصب خودکار تمام شود (npm install، Postgres، migrate، seed). ۴. در ترمینال: `npm run dev` و پورت ۳۰۰۰ را باز کنید.

## اجرا روی کامپیوتر خودتان
نیاز: Node.js 20+ و Docker.
```bash
cp .env.example .env
npm install
npm run db:up      # Postgres
npm run migrate    # ساخت جدول‌ها
npm run seed       # ادمین، همکاران نمونه، ۸ محصول با عکس
npm run dev        # http://localhost:3000
npm test           # تست‌های پورسانت (به دیتابیس نیاز دارد)
```

## حساب‌های آزمایشی (بعد از seed)
| نقش | ایمیل | رمز |
|---|---|---|
| ادمین | admin@example.com | Admin12345 |
| همکار (سطح بالا) | sara@example.com | Test12345 |
| همکار | ali@example.com (معرف: سارا) | Test12345 |
| همکار | nazanin@example.com (معرف: علی) | Test12345 |
| خریدار | buyer@example.com (معرف: نازنین) | Test12345 |

لینک ارجاع سارا: `/r/SARA2410` (برای یک محصول: `/r/SARA2410?p=1`).

## سناریوی آزمایش پیشنهادی
1. در یک پنجره ناشناس لینک `/r/SARA2410` را باز کنید ← ثبت‌نام ← یک محصول بخرید.
2. با ادمین وارد شوید ← **سفارش‌ها** ← «تحویل شد» (برای پرداخت در محل: «تحویل + دریافت پول»).
3. **پورسانت‌ها** ← «تأیید پورسانت‌های سررسید» (مهلت مرجوعی در seed روی ۰ روز است).
4. با سارا وارد شوید ← پنل همکار: پورسانت ۵٪ و موجودی را ببینید. با `buyer@example.com` خرید کنید تا ۳ سطح (۵٪، ۳٪، ۲٪) را ببینید.
5. در ادمین یک سفارش را «مرجوع» کنید و کسر پورسانت را ببینید.
6. ادمین ← **محصولات** ← محصول جدید ← عکس‌ها را انتخاب و ذخیره کنید.

## قوانین پورسانت (پیاده‌سازی‌شده)
- فقط از **مبلغ خالص محصولات** (بدون ارسال/مالیات) و فقط بعد از **پرداخت قطعی**؛ ثبت‌نام پورسانت ندارد.
- تا ۳ سطح؛ نرخ‌ها در ادمین قابل تغییر (نسخه‌دار) و مجموعشان زیر سقف (پیش‌فرض ۱۵٪).
- پورسانت ابتدا «در انتظار» است؛ بعد از **تحویل** و پایان **مهلت مرجوعی** تأیید و به کیف پول اضافه می‌شود.
- مرجوعی: پورسانت pending کم می‌شود؛ پورسانت تأییدشده از کیف پول کسر می‌شود.
- معرف (sponsor): از لینک (کوکی ۳۰ روزه) هنگام ثبت‌نام، یا هنگام **اولین خرید** برای کسی که معرف ندارد؛ بعد از آن در دیتابیس تغییرناپذیر است.
- همکار تعلیق‌شده پورسانت نمی‌گیرد. کد معرف خودی پورسانت ندارد و پرچم ضدتقلب می‌سازد.

## ساختار
```
migrations/001_init.sql          اسکیمای دیتابیس
src/modules/commission/          الگوریتم پورسانت (قلب سیستم)
src/modules/{auth,catalog,orders,affiliate,admin}/
src/scripts/                     migrate, seed, approve
public/                          فرانت‌اند (index.html, app.js, style.css)
tests/commission.test.ts         تست‌ها (هر تست داخل تراکنش و بدون اثر باقی‌مانده)
uploads/                         عکس‌های آپلودشده (داخل git نمی‌روند)
```

## قبل از انتشار واقعی (حتماً)
- `JWT_SECRET` قوی بگذارید، `COOKIE_SECURE=true` و فقط روی HTTPS.
- **پرداخت آنلاین فعلاً آزمایشی است** (سفارش بلافاصله «پرداخت‌شده» می‌شود). درگاه واقعی را وصل کنید و فقط بعد از تأیید درگاه `onOrderPaid` را صدا بزنید.
- عکس‌ها روی دیسک سرور ذخیره می‌شوند؛ در هاست‌هایی که دیسک موقتی دارند (مثل Render رایگان) از S3/Cloudinary استفاده کنید.
- مهلت مرجوعی را در ادمین به مقدار واقعی (مثلاً ۱۴ روز) برگردانید و `npm run approve` را روزانه با cron اجرا کنید.
- اضافه کنید: محدودیت تعداد درخواست (rate limit)، تأیید ایمیل/موبایل، بازیابی رمز، پشتیبان‌گیری دیتابیس.
- قوانین بازاریابی شبکه‌ای و مالیات کشور هدف را با مشاور حقوقی بررسی کنید.
__EOF_FILE__
mkdir -p "$(dirname "docker-compose.yml")"
cat > 'docker-compose.yml' <<'__EOF_FILE__'
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: shop
      POSTGRES_PASSWORD: shop
      POSTGRES_DB: shop
    ports: ["5432:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U shop -d shop"]
      interval: 3s
      timeout: 3s
      retries: 20
volumes:
  pgdata:
__EOF_FILE__
mkdir -p "$(dirname "migrations/001_init.sql")"
cat > 'migrations/001_init.sql' <<'__EOF_FILE__'
CREATE TABLE users (
  id            BIGSERIAL PRIMARY KEY,
  name          TEXT NOT NULL DEFAULT '',
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL DEFAULT '',
  role          TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer','admin')),
  referral_code TEXT UNIQUE NOT NULL,
  sponsor_id    BIGINT REFERENCES users(id),
  is_affiliate  BOOLEAN NOT NULL DEFAULT false,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  signup_ip     TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (sponsor_id IS NULL OR sponsor_id <> id)
);
CREATE INDEX ON users(sponsor_id);

-- معرف فقط یک‌بار (NULL → مقدار) قابل تعیین است و بعد تغییرناپذیر می‌شود
CREATE FUNCTION forbid_sponsor_change() RETURNS trigger AS $$
BEGIN
  IF OLD.sponsor_id IS NOT NULL AND NEW.sponsor_id IS DISTINCT FROM OLD.sponsor_id THEN
    RAISE EXCEPTION 'sponsor_id is immutable';
  END IF;
  RETURN NEW;
END $$ LANGUAGE plpgsql;
CREATE TRIGGER users_sponsor_immutable BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION forbid_sponsor_change();

CREATE TABLE products (
  id                  BIGSERIAL PRIMARY KEY,
  sku                 TEXT UNIQUE NOT NULL,
  name                TEXT NOT NULL,
  category            TEXT NOT NULL DEFAULT 'سایر',
  brief               TEXT NOT NULL DEFAULT '',
  description         TEXT NOT NULL DEFAULT '',
  usage_instructions  TEXT NOT NULL DEFAULT '',
  ingredients         TEXT NOT NULL DEFAULT '',
  price               BIGINT NOT NULL CHECK (price >= 0),
  stock               INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
  commission_eligible BOOLEAN NOT NULL DEFAULT true,
  is_active           BOOLEAN NOT NULL DEFAULT true,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE product_images (
  id         BIGSERIAL PRIMARY KEY,
  product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  url        TEXT NOT NULL,
  sort       INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ON product_images(product_id, sort);

CREATE TABLE orders (
  id             BIGSERIAL PRIMARY KEY,
  buyer_id       BIGINT NOT NULL REFERENCES users(id),
  status         TEXT NOT NULL CHECK (status IN ('pending','paid','delivered','refunded','cancelled')),
  payment_method TEXT NOT NULL DEFAULT 'online_test',
  address        TEXT NOT NULL DEFAULT '',
  phone          TEXT NOT NULL DEFAULT '',
  paid_at        TIMESTAMPTZ,
  delivered_at   TIMESTAMPTZ,
  shipping       BIGINT NOT NULL DEFAULT 0,
  tax            BIGINT NOT NULL DEFAULT 0,
  total          BIGINT NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ON orders(buyer_id);

CREATE TABLE order_items (
  id              BIGSERIAL PRIMARY KEY,
  order_id        BIGINT NOT NULL REFERENCES orders(id),
  product_id      BIGINT NOT NULL REFERENCES products(id),
  qty             INT NOT NULL CHECK (qty > 0),
  net_amount      BIGINT NOT NULL,
  refunded_amount BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX ON order_items(order_id);

CREATE TABLE commission_rules (
  id         BIGSERIAL PRIMARY KEY,
  level      SMALLINT NOT NULL CHECK (level BETWEEN 1 AND 3),
  product_id BIGINT REFERENCES products(id),
  rate_bps   INT NOT NULL CHECK (rate_bps BETWEEN 0 AND 10000),
  valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
  valid_to   TIMESTAMPTZ
);

CREATE TABLE commissions (
  id             BIGSERIAL PRIMARY KEY,
  order_id       BIGINT NOT NULL REFERENCES orders(id),
  order_item_id  BIGINT NOT NULL REFERENCES order_items(id),
  beneficiary_id BIGINT NOT NULL REFERENCES users(id),
  level          SMALLINT NOT NULL CHECK (level BETWEEN 1 AND 3),
  base_amount    BIGINT NOT NULL,
  rate_bps       INT NOT NULL,
  amount         BIGINT NOT NULL,
  status         TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','reversed','paid')),
  approve_after  TIMESTAMPTZ NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (order_item_id, beneficiary_id, level)
);
CREATE INDEX ON commissions(beneficiary_id, status);
CREATE INDEX ON commissions(status, approve_after);

CREATE TABLE wallet_entries (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT NOT NULL REFERENCES users(id),
  amount     BIGINT NOT NULL,
  type       TEXT NOT NULL CHECK (type IN ('commission','clawback','payout','adjust')),
  ref_id     BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ON wallet_entries(user_id);
CREATE UNIQUE INDEX wallet_commission_once ON wallet_entries(ref_id) WHERE type = 'commission';

CREATE TABLE payouts (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT NOT NULL REFERENCES users(id),
  amount     BIGINT NOT NULL CHECK (amount > 0),
  method     TEXT NOT NULL DEFAULT '',
  account    TEXT NOT NULL DEFAULT '',
  status     TEXT NOT NULL DEFAULT 'requested' CHECK (status IN ('requested','paid','rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);

CREATE TABLE fraud_flags (
  id         BIGSERIAL PRIMARY KEY,
  type       TEXT NOT NULL,
  severity   TEXT NOT NULL CHECK (severity IN ('high','medium','low')),
  user_id    BIGINT REFERENCES users(id),
  detail     TEXT NOT NULL DEFAULT '',
  status     TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','resolved')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE audit_log (
  id         BIGSERIAL PRIMARY KEY,
  admin_id   BIGINT REFERENCES users(id),
  action     TEXT NOT NULL,
  detail     TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
__EOF_FILE__
mkdir -p "$(dirname "package.json")"
cat > 'package.json' <<'__EOF_FILE__'
{
  "name": "golrokh-shop",
  "version": "0.2.0",
  "private": true,
  "scripts": {
    "dev": "tsx watch src/server.ts",
    "start": "tsx src/server.ts",
    "db:up": "docker compose up -d --wait",
    "migrate": "tsx src/scripts/migrate.ts",
    "seed": "tsx src/scripts/seed.ts",
    "approve": "tsx src/scripts/approve.ts",
    "test": "tsx --test tests/*.test.ts",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cookie-parser": "^1.4.6",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "jsonwebtoken": "^9.0.2",
    "multer": "^2.0.2",
    "pg": "^8.12.0"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/cookie-parser": "^1.4.7",
    "@types/express": "^4.17.21",
    "@types/jsonwebtoken": "^9.0.6",
    "@types/multer": "^1.4.12",
    "@types/node": "^20.14.0",
    "@types/pg": "^8.11.6",
    "tsx": "^4.16.0",
    "typescript": "^5.5.0"
  }
}
__EOF_FILE__
mkdir -p "$(dirname "public/app.js")"
cat > 'public/app.js' <<'__EOF_FILE__'
/* گل‌رخ — فرانت‌اند ساده (بدون فریم‌ورک). همه داده‌ها از /api می‌آیند. */
const $ = s => document.querySelector(s);
const fmt = n => Number(n || 0).toLocaleString('fa-AF');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const nl = s => esc(s).replace(/\n/g, '<br>');
const date = d => d && d !== 'infinity' ? new Date(d).toLocaleDateString('fa-AF') : '—';
const STATUS = { pending: ['در انتظار', 'b-warn'], approved: ['تأیید شده', 'b-ok'], reversed: ['برگشت‌خورده', 'b-bad'], paid: ['پرداخت‌شده', 'b-ok'],
  delivered: ['تحویل‌شده', 'b-ok'], refunded: ['مرجوع', 'b-bad'], cancelled: ['لغو', 'b-bad'], requested: ['در انتظار بررسی', 'b-warn'], rejected: ['رد شد', 'b-bad'] };
const badge = s => { const [t, c] = STATUS[s] || [s, 'b-warn']; return `<span class="badge ${c}">${t}</span>`; };

let me = null, cart = JSON.parse(localStorage.getItem('cart') || '[]');
const saveCart = () => { localStorage.setItem('cart', JSON.stringify(cart)); nav(); };

async function api(path, opt = {}) {
  const o = { credentials: 'same-origin', ...opt };
  if (o.body && !(o.body instanceof FormData)) { o.headers = { 'Content-Type': 'application/json' }; o.body = JSON.stringify(o.body); }
  const r = await fetch('/api' + path, o);
  const d = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(d.error || 'خطا در ارتباط با سرور');
  return d;
}
function toast(msg, err) {
  const t = document.createElement('div'); t.className = 'toast' + (err ? ' err' : ''); t.textContent = msg;
  document.body.appendChild(t); setTimeout(() => t.remove(), 3000);
}
const act = fn => async (...a) => { try { await fn(...a); } catch (e) { toast(e.message, true); } };
const val = id => document.getElementById(id)?.value ?? '';

/* ---------- ناوبری ---------- */
function nav() {
  const n = cart.reduce((a, c) => a + c.qty, 0);
  $('#nav').innerHTML = `
    <a class="tab" href="#/">فروشگاه</a>
    <a class="tab" href="#/guide">رهنما</a>
    ${me ? `<a class="tab" href="#/dashboard">پنل همکار</a><a class="tab" href="#/orders">سفارش‌های من</a>` : ''}
    ${me?.role === 'admin' ? `<a class="tab" href="#/admin">ادمین</a>` : ''}
    <a class="tab" href="#/cart">🛒 ${fmt(n)}</a>
    ${me ? `<button class="hdr-btn" onclick="logout()">خروج (${esc(me.name)})</button>` : `<a class="tab" href="#/login">ورود / ثبت‌نام</a>`}`;
}
window.logout = act(async () => { await api('/auth/logout', { method: 'POST' }); me = null; nav(); location.hash = '#/'; });

/* ---------- مسیریابی ---------- */
const routes = { '': shop, product, cart: cartPage, login, register, orders, guide, dashboard, admin };
async function route() {
  const [name, arg] = location.hash.replace(/^#\/?/, '').split('?')[0].split('/');
  $('#app').innerHTML = '<div class="empty">در حال بارگذاری…</div>';
  try { await (routes[name] || shop)(arg); } catch (e) { $('#app').innerHTML = `<div class="box empty">${esc(e.message)}</div>`; }
  scrollTo(0, 0);
}
addEventListener('hashchange', route);
(async () => { try { me = await api('/auth/me'); } catch {} nav(); route(); })();

/* ---------- فروشگاه ---------- */
async function shop() {
  const cat = new URLSearchParams(location.hash.split('?')[1] || '').get('c') || '';
  const [cats, list, ref] = await Promise.all([api('/categories'), api('/products' + (cat ? '?category=' + encodeURIComponent(cat) : '')), api('/auth/referrer')]);
  $('#app').innerHTML = `
    ${ref.name ? `<div class="banner-ref">🤝 شما با لینک «${esc(ref.name)}» وارد شده‌اید؛ خرید شما به نام او ثبت می‌شود.</div>` : ''}
    <div class="hero"><div><h1>مراقبت از پوست،<br>با محصولات اصل و مطمئن</h1>
      <p>ارسال سریع، ضمانت اصالت کالا و مهلت بازگشت.</p>
      <a class="btn ghost" href="#/guide">همکاری در فروش</a></div><div class="blob"></div></div>
    <div class="cats"><a class="chip" href="#/">همه</a>${cats.map(c => `<a class="chip" href="#/?c=${encodeURIComponent(c)}">${esc(c)}</a>`).join('')}</div>
    <div class="grid">${list.map(p => `
      <a class="p" href="#/product/${p.id}"><div class="ph" style="background:var(--soft)">${p.image ? `<img src="${esc(p.image)}" alt="${esc(p.name)}">` : '🌸'}</div>
        <div class="pb"><b>${esc(p.name)}</b><br><small>${esc(p.category)}</small>
        <div class="price"><span>${fmt(p.price)} <small>افغانی</small></span>${p.stock < 1 ? '<span class="badge b-bad">ناموجود</span>' : ''}</div></div></a>`).join('') || '<div class="empty">محصولی ثبت نشده است.</div>'}</div>`;
}

async function product(id) {
  const p = await api('/products/' + id);
  const imgs = p.images;
  const sec = (t, x) => x ? `<div class="sec"><h3>${t}</h3><p>${nl(x)}</p></div>` : '';
  const rate = me?.is_affiliate ? `<button class="earn" onclick="copyLink(${p.id})"><span>🔗 اشتراک این محصول با لینک اختصاصی شما</span><span>کپی</span></button>` : '';
  $('#app').innerHTML = `<div class="gal"><div>
      <div class="main" id="mainImg">${imgs[0] ? `<img src="${esc(imgs[0].url)}" alt="">` : '🌸'}</div>
      <div class="thumbs">${imgs.map((i, k) => `<img src="${esc(i.url)}" class="${k ? '' : 'on'}" onclick="pick(this)">`).join('')}</div></div>
    <div><h2 style="font-size:24px">${esc(p.name)}</h2><small style="color:var(--muted)">${esc(p.category)} · کد: ${esc(p.sku)}</small>
      <p style="margin:10px 0">${esc(p.brief)}</p>
      <div style="font-size:24px;font-weight:700;color:var(--brand)">${fmt(p.price)} <small style="font-size:14px">افغانی</small></div>
      <p class="note">${p.stock > 0 ? `موجودی: ${fmt(p.stock)} عدد` : 'ناموجود'}</p>
      <div class="qty" style="margin:14px 0"><button onclick="q(-1)">−</button><b id="qv">1</b><button onclick="q(1)">+</button>
        <button class="btn" style="width:auto;height:auto;color:#fff;background:var(--brand);padding:10px 22px;font-size:15px" ${p.stock < 1 ? 'disabled' : ''} onclick="addCart(${p.id})">افزودن به سبد</button></div>
      ${rate}</div></div>
    ${sec('توضیحات', p.description)}${sec('روش مصرف', p.usage_instructions)}${sec('ترکیبات و اطلاعات', p.ingredients)}`;
  window._p = p;
}
window.pick = el => { $('#mainImg').innerHTML = `<img src="${el.src}" alt="">`; document.querySelectorAll('.thumbs img').forEach(i => i.classList.toggle('on', i === el)); };
window.q = d => { const e = $('#qv'); e.textContent = Math.min(50, Math.max(1, +e.textContent + d)); };
window.addCart = id => {
  const p = window._p, n = +$('#qv').textContent, row = cart.find(c => c.id === id);
  if (row) row.qty += n; else cart.push({ id, name: p.name, price: p.price, image: p.images[0]?.url || '', qty: n });
  saveCart(); toast('به سبد خرید اضافه شد');
};
window.copyLink = id => { navigator.clipboard?.writeText(`${location.origin}/r/${me.referral_code}?p=${id}`); toast('لینک اختصاصی کپی شد'); };

/* ---------- سبد خرید ---------- */
async function cartPage() {
  const ref = await api('/auth/referrer');
  const sub = cart.reduce((a, c) => a + c.price * c.qty, 0);
  const settings = await api('/shipping').catch(() => ({ shipping_fee: 0 }));
  if (!cart.length) { $('#app').innerHTML = '<div class="box empty">سبد خرید خالی است.</div>'; return; }
  const noRef = me && me.sponsor_name;
  $('#app').innerHTML = `<h2>سبد خرید و ثبت سفارش</h2><div class="cols">
    <div class="box">${cart.map((c, i) => `<div class="cartrow"><div class="ic" style="background:var(--soft)">${c.image ? `<img src="${esc(c.image)}" style="width:56px;height:56px;object-fit:cover;border-radius:12px">` : '🌸'}</div>
        <div><b>${esc(c.name)}</b><br><small style="color:var(--muted)">${fmt(c.price)} × ${fmt(c.qty)}</small></div>
        <div class="qty"><button onclick="cq(${i},-1)">−</button><b>${fmt(c.qty)}</b><button onclick="cq(${i},1)">+</button></div>
        <b>${fmt(c.price * c.qty)}</b></div>`).join('')}
      <label>آدرس تحویل</label><textarea id="addr"></textarea>
      <div class="row2"><div><label>شماره تماس</label><input type="tel" id="phone" dir="ltr" placeholder="07x xxx xxxx"></div>
      <div><label>روش پرداخت</label><select id="pm"><option value="online_test">پرداخت آنلاین (آزمایشی)</option><option value="cod">پرداخت در محل</option></select></div></div>
      ${noRef ? `<div class="sp">🤝 معرفی‌شده توسط: ${esc(me.sponsor_name)}</div>` : `
      <label>کد معرف (اختیاری)</label><input type="text" id="rc" dir="ltr" value="${esc(ref.code || '')}" placeholder="مثلاً SARA2410">
      ${ref.name ? `<div class="sp">🤝 معرفی‌شده توسط: ${esc(ref.name)}</div>` : ''}
      <p class="note">کد معرف بعد از اولین خرید قابل تغییر نیست. کد خودتان پورسانتی ندارد.</p>`}</div>
    <div class="box"><b>خلاصه سفارش</b><div class="sum" style="margin-top:8px">
      <div><span>مبلغ خالص محصولات</span><span>${fmt(sub)}</span></div>
      <div><span>ارسال</span><span>${fmt(settings.shipping_fee)}</span></div>
      <div class="t"><span>مبلغ قابل پرداخت</span><span>${fmt(sub + settings.shipping_fee)} افغانی</span></div></div>
      <p class="note">پورسانت همکاران فقط از «مبلغ خالص محصولات» محاسبه می‌شود.</p>
      <button class="btn" style="width:100%;margin-top:10px" onclick="placeOrder()">ثبت سفارش</button></div></div>`;
}
window.cq = (i, d) => { cart[i].qty += d; if (cart[i].qty < 1) cart.splice(i, 1); saveCart(); cartPage(); };
window.placeOrder = act(async () => {
  if (!me) { location.hash = '#/login'; return toast('ابتدا وارد شوید', true); }
  const r = await api('/orders', { method: 'POST', body: { items: cart.map(c => ({ product_id: c.id, qty: c.qty })),
    address: val('addr'), phone: val('phone'), payment_method: val('pm'), refCode: val('rc') } });
  cart = []; saveCart(); me = await api('/auth/me');
  $('#app').innerHTML = `<div class="box empty"><h2>✅ سفارش #${r.id} ثبت شد</h2><p>مبلغ: ${fmt(r.total)} افغانی</p><a class="btn" href="#/orders">سفارش‌های من</a></div>`;
});

async function orders() {
  if (!me) return (location.hash = '#/login');
  const list = await api('/orders/mine');
  $('#app').innerHTML = `<h2>سفارش‌های من</h2><div class="box"><div class="tw"><table><tr><th>#</th><th>تاریخ</th><th>محصولات</th><th>مبلغ</th><th>وضعیت</th></tr>
    ${list.map(o => `<tr><td>${o.id}</td><td>${date(o.created_at)}</td><td>${(o.items || []).map(i => esc(i.name) + ' ×' + i.qty).join('، ')}</td><td>${fmt(o.total)}</td><td>${badge(o.status)}</td></tr>`).join('') || '<tr><td colspan=5 class="empty">سفارشی ندارید</td></tr>'}</table></div></div>`;
}

/* ---------- ورود / ثبت‌نام ---------- */
async function login() {
  $('#app').innerHTML = `<div class="box" style="max-width:420px;margin:auto"><h2>ورود</h2>
    <label>ایمیل</label><input type="email" id="em" dir="ltr"><label>رمز عبور</label><input type="password" id="pw" dir="ltr">
    <button class="btn" style="width:100%;margin-top:14px" onclick="doLogin()">ورود</button>
    <p class="note">حساب ندارید؟ <a href="#/register" style="color:var(--brand)">ثبت‌نام</a></p></div>`;
}
window.doLogin = act(async () => { me = await api('/auth/login', { method: 'POST', body: { email: val('em'), password: val('pw') } }); me = await api('/auth/me'); nav(); location.hash = '#/'; });
async function register() {
  const ref = await api('/auth/referrer');
  $('#app').innerHTML = `<div class="box" style="max-width:420px;margin:auto"><h2>ثبت‌نام</h2>
    ${ref.name ? `<div class="sp">🤝 معرفی‌شده توسط: ${esc(ref.name)}</div>` : ''}
    <label>نام</label><input type="text" id="nm"><label>ایمیل</label><input type="email" id="em" dir="ltr">
    <label>رمز عبور (حداقل ۸ کاراکتر)</label><input type="password" id="pw" dir="ltr">
    <button class="btn" style="width:100%;margin-top:14px" onclick="doRegister()">ایجاد حساب</button></div>`;
}
window.doRegister = act(async () => { await api('/auth/register', { method: 'POST', body: { name: val('nm'), email: val('em'), password: val('pw') } }); me = await api('/auth/me'); nav(); location.hash = '#/'; });

/* ---------- رهنما ---------- */
async function guide() {
  const faq = [
    ['پورسانت از چه چیزی پرداخت می‌شود؟', 'فقط از خرید قطعی محصول. ثبت‌نام، معرفی افراد یا هزینه عضویت پورسانتی ندارد.'],
    ['سطح ۱، ۲ و ۳ یعنی چه؟', 'سطح ۱ خریداران مستقیم لینک شما، سطح ۲ معرفی‌شده‌های آنان و سطح ۳ معرفی‌شده‌های سطح ۲. بیشتر از ۳ سطح نداریم.'],
    ['پورسانت کی به موجودی من اضافه می‌شود؟', 'پس از پرداخت، «در انتظار» ثبت می‌شود؛ بعد از تحویل کالا و پایان مهلت مرجوعی تأیید و به کیف پول می‌رود.'],
    ['اگر مشتری کالا را مرجوع کند؟', 'پورسانت همان کالا کم یا برگشت داده می‌شود؛ اگر قبلاً تأیید شده باشد، از موجودی بعدی کسر می‌شود.'],
    ['معرف من چه زمانی ثبت می‌شود؟', 'با ورود از لینک همکار، تا ۳۰ روز در مرورگر می‌ماند و هنگام ثبت‌نام (یا اولین خرید) ثبت می‌شود؛ بعد از آن تغییر نمی‌کند.'],
    ['آیا باید هزینه‌ای بپردازم؟', 'خیر. همکاری رایگان است و خرید اجباری وجود ندارد.'],
    ['خرید با کد خودم پورسانت دارد؟', 'خیر؛ خرید با کد خودی پورسانت ندارد و بررسی می‌شود.'],
  ];
  $('#app').innerHTML = `<h2>رهنمای همکاری در فروش</h2>
    <div class="box"><b>مثال:</b> خرید ۱,۰۰۰ افغانی (مبلغ خالص) ← معرف مستقیم ۵۰، سطح ۲ مبلغ ۳۰ و سطح ۳ مبلغ ۲۰ افغانی (نرخ‌های نمونه).
      <p class="note">درآمد وابسته به فروش واقعی است و تضمین‌شده نیست.</p>
      ${me ? (me.is_affiliate ? '<a class="btn" href="#/dashboard">پنل همکار</a>' : '<button class="btn" onclick="joinAff()">همکار فروش شوید (رایگان)</button>') : '<a class="btn" href="#/register">ثبت‌نام</a>'}</div>
    <div class="faq">${faq.map(([q, a]) => `<details><summary>${q}</summary><p>${a}</p></details>`).join('')}</div>`;
}
window.joinAff = act(async () => { await api('/auth/affiliate/join', { method: 'POST' }); me = await api('/auth/me'); nav(); location.hash = '#/dashboard'; });

/* ---------- پنل همکار ---------- */
async function dashboard() {
  if (!me) return (location.hash = '#/login');
  const s = await api('/affiliate/summary');
  if (!s.is_affiliate) { $('#app').innerHTML = `<div class="box empty"><h2>هنوز همکار فروش نیستید</h2><button class="btn" onclick="joinAff()">فعال‌سازی رایگان</button></div>`; return; }
  const link = `${location.origin}/r/${s.referral_code}`;
  $('#app').innerHTML = `<h2>سلام ${esc(me.name)} 👋</h2>
    <div class="stats"><div class="stat"><span>موجودی قابل برداشت</span><b>${fmt(s.balance)} افغانی</b></div>
      <div class="stat"><span>در انتظار تأیید</span><b>${fmt(s.pending)} افغانی</b></div>
      <div class="stat"><span>مجموع کسب‌درآمد</span><b>${fmt(s.earned)} افغانی</b></div>
      <div class="stat"><span>شبکه (سطح ۱/۲/۳)</span><b>${s.network.map(fmt).join(' / ')}</b></div></div>
    <div class="box"><b>لینک اختصاصی شما</b><div class="link" style="margin-top:10px"><input type="text" id="lk" readonly value="${esc(link)}" style="direction:ltr">
      <button class="btn" onclick="navigator.clipboard?.writeText($('#lk').value);toast('کپی شد')">کپی لینک</button></div>
      <p class="note">برای لینک هر محصول، صفحه محصول را باز کنید و «اشتراک» را بزنید.</p></div>
    <div class="cols"><div class="box"><b>شبکه شما (نام‌ها نیمه‌پنهان)</b><div style="margin-top:8px">
      ${s.tree.map(t => `<div class="lv" style="margin-inline-start:${(t.lvl - 1) * 20}px"><div class="dot l${t.lvl}">${t.lvl}</div><div style="flex:1">${esc(t.name)}</div><span>${fmt(t.sales)}</span></div>`).join('') || '<p class="note">هنوز کسی از لینک شما وارد نشده است.</p>'}</div></div>
    <div class="box"><b>درخواست برداشت</b><label>مبلغ (حداقل ${fmt(s.min_payout)})</label><input type="number" id="pa">
      <label>روش</label><select id="pmth"><option>حواله بانکی</option><option>کیف پول موبایل</option></select>
      <label>شماره حساب / کیف پول</label><input type="text" id="pac" dir="ltr">
      <button class="btn" style="width:100%;margin-top:12px" onclick="reqPayout()">ثبت درخواست</button></div></div>
    <div class="box"><b>آخرین پورسانت‌ها</b><div class="tw"><table><tr><th>سفارش</th><th>سطح</th><th>مبلغ خالص</th><th>نرخ</th><th>پورسانت</th><th>وضعیت</th><th>تأیید در</th></tr>
      ${s.commissions.map(c => `<tr><td>#${c.order_id}</td><td>${c.level}</td><td>${fmt(c.base_amount)}</td><td>${c.rate_bps / 100}٪</td><td>${fmt(c.amount)}</td><td>${badge(c.status)}</td><td>${c.status === 'pending' ? date(c.approve_after) : '—'}</td></tr>`).join('') || '<tr><td colspan=7 class="empty">هنوز پورسانتی ندارید</td></tr>'}</table></div></div>
    <div class="cols"><div class="box"><b>تاریخچه کیف پول</b><div class="tw"><table>${s.wallet.map(w => `<tr><td>${date(w.created_at)}</td><td>${{ commission: 'پورسانت', clawback: 'کسر مرجوعی', payout: 'برداشت', adjust: 'اصلاح' }[w.type]}</td><td class="${w.amount < 0 ? 'neg' : 'pos'}">${fmt(w.amount)}</td></tr>`).join('') || '<tr><td class="empty">خالی</td></tr>'}</table></div></div>
    <div class="box"><b>برداشت‌ها</b><div class="tw"><table>${s.payouts.map(p => `<tr><td>${date(p.created_at)}</td><td>${esc(p.method)}</td><td>${fmt(p.amount)}</td><td>${badge(p.status)}</td></tr>`).join('') || '<tr><td class="empty">خالی</td></tr>'}</table></div></div></div>`;
}
window.reqPayout = act(async () => { await api('/affiliate/payouts', { method: 'POST', body: { amount: val('pa'), method: val('pmth'), account: val('pac') } }); toast('درخواست ثبت شد'); dashboard(); });

/* ---------- پنل ادمین ---------- */
let admTab = 'products';
const ADM = [['products', 'محصولات'], ['orders', 'سفارش‌ها'], ['commissions', 'پورسانت‌ها'], ['payouts', 'برداشت‌ها'], ['rules', 'نرخ‌ها و تنظیمات'], ['users', 'همکاران'], ['flags', 'ضدتقلب'], ['audit', 'لاگ']];
async function admin() {
  if (me?.role !== 'admin') throw new Error('دسترسی ندارید');
  const st = await api('/admin/stats');
  $('#app').innerHTML = `<h2>پنل مدیریت</h2>
    <div class="stats"><div class="stat"><span>فروش (خالص)</span><b>${fmt(st.sales)}</b></div><div class="stat"><span>سفارش‌ها</span><b>${fmt(st.orders)}</b></div>
      <div class="stat"><span>پورسانت تأییدشده</span><b>${fmt(st.commissions_approved)}</b></div><div class="stat"><span>پورسانت در انتظار</span><b>${fmt(st.commissions_pending)}</b></div>
      <div class="stat"><span>همکاران</span><b>${fmt(st.affiliates)}</b></div><div class="stat"><span>برداشت باز / پرچم باز</span><b>${fmt(st.payouts_open)} / ${fmt(st.flags_open)}</b></div></div>
    <div class="atabs">${ADM.map(([k, t]) => `<button class="atab ${k === admTab ? 'on' : ''}" onclick="admGo('${k}')">${t}</button>`).join('')}</div><div id="adm"></div>`;
  await admViews[admTab]();
}
window.admGo = act(async k => { admTab = k; await admin(); });
const A = (path, method = 'POST', body) => api('/admin' + path, { method, body });
const admViews = {
  async products() {
    const list = await api('/admin/products');
    $('#adm').innerHTML = `<div class="box"><div class="tools"><b style="flex:1;align-self:center">محصولات</b><button class="btn" onclick="editProduct(null)">+ محصول جدید</button></div>
      <div id="pform"></div><div class="tw"><table><tr><th></th><th>نام</th><th>کد</th><th>دسته</th><th>قیمت</th><th>موجودی</th><th>عکس</th><th>وضعیت</th><th></th></tr>
      ${list.map(p => `<tr><td>${p.image ? `<img src="${esc(p.image)}" width="40" height="40" style="object-fit:cover;border-radius:8px">` : ''}</td><td>${esc(p.name)}</td><td>${esc(p.sku)}</td><td>${esc(p.category)}</td><td>${fmt(p.price)}</td><td>${fmt(p.stock)}</td><td>${p.image_count}</td>
      <td>${p.is_active ? badge('paid').replace('پرداخت‌شده', 'فعال') : '<span class="badge b-bad">غیرفعال</span>'}</td><td><button class="sm" onclick="editProduct(${p.id})">ویرایش</button></td></tr>`).join('')}</table></div></div>`;
  },
  async orders() {
    const list = await api('/admin/orders');
    $('#adm').innerHTML = `<div class="box"><div class="tw"><table><tr><th>#</th><th>خریدار</th><th>معرف</th><th>محصولات</th><th>مبلغ</th><th>پورسانت کل</th><th>وضعیت</th><th>عملیات</th></tr>
      ${list.map(o => `<tr><td>${o.id}</td><td>${esc(o.buyer)}<br><small>${esc(o.phone)}</small></td><td>${esc(o.sponsor || '—')}</td>
      <td>${(o.items || []).map(i => `${esc(i.name)} ×${i.qty}${i.refunded < i.net ? ` <button class="sm no" onclick="refund(${o.id},${i.id})">مرجوع</button>` : ' (مرجوع)'}`).join('<br>')}</td>
      <td>${fmt(o.total)}</td><td>${fmt(o.commission_total)}</td><td>${badge(o.status)}</td>
      <td>${['pending', 'paid'].includes(o.status) ? `<button class="sm ok" onclick="deliver(${o.id})">${o.status === 'pending' ? 'تحویل + دریافت پول' : 'تحویل شد'}</button>` : ''}</td></tr>`).join('')}</table></div></div>`;
  },
  async commissions() {
    const list = await api('/admin/commissions');
    $('#adm').innerHTML = `<div class="box"><div class="tools"><b style="flex:1;align-self:center">دفتر پورسانت</b><button class="btn" onclick="approveNow()">تأیید پورسانت‌های سررسید</button></div>
      <div class="tw"><table><tr><th>سفارش</th><th>همکار</th><th>سطح</th><th>مبلغ خالص</th><th>نرخ</th><th>پورسانت</th><th>وضعیت</th><th>تأیید در</th></tr>
      ${list.map(c => `<tr><td>#${c.order_id}</td><td>${esc(c.beneficiary)}</td><td>${c.level}</td><td>${fmt(c.base_amount)}</td><td>${c.rate_bps / 100}٪</td><td>${fmt(c.amount)}</td><td>${badge(c.status)}</td><td>${c.status === 'pending' ? date(c.approve_after) : '—'}</td></tr>`).join('')}</table></div></div>`;
  },
  async payouts() {
    const list = await api('/admin/payouts');
    $('#adm').innerHTML = `<div class="box"><div class="tw"><table><tr><th>همکار</th><th>مبلغ</th><th>روش</th><th>حساب</th><th>موجودی فعلی</th><th>وضعیت</th><th></th></tr>
      ${list.map(p => `<tr><td>${esc(p.user_name)}</td><td>${fmt(p.amount)}</td><td>${esc(p.method)}</td><td dir="ltr">${esc(p.account)}</td><td>${fmt(p.balance)}</td><td>${badge(p.status)}</td>
      <td>${p.status === 'requested' ? `<button class="sm ok" onclick="payout(${p.id},'approve')">پرداخت شد</button> <button class="sm no" onclick="payout(${p.id},'reject')">رد</button>` : ''}</td></tr>`).join('')}</table></div></div>`;
  },
  async rules() {
    const [r, s] = await Promise.all([api('/admin/rules'), api('/admin/settings')]);
    $('#adm').innerHTML = `<div class="cols"><div class="box"><b>نرخ پورسانت (٪)</b>
      ${[1, 2, 3].map(l => `<div class="rate"><span>سطح ${l}</span><input type="number" step="0.5" min="0" class="rt" value="${r.rates[l - 1] / 100}"></div>`).join('')}
      <p class="note">سقف مجموع سه سطح: ${r.cap_bps / 100}٪ (از «سقف» در تنظیمات)</p><button class="btn" style="width:100%" onclick="saveRules()">ذخیره نسخه جدید</button>
      <ul class="audit">${r.history.slice(0, 6).map(h => `<li>سطح ${h.level}: ${h.rate_bps / 100}٪ <small>از ${date(h.valid_from)}${h.valid_to ? ' تا ' + date(h.valid_to) : ' (فعلی)'}</small></li>`).join('')}</ul></div>
      <div class="box"><b>تنظیمات</b>
      <div class="rate"><span>مهلت مرجوعی (روز)</span><input type="number" id="s_hold" value="${esc(s.hold_days)}"></div>
      <div class="rate"><span>حداقل برداشت</span><input type="number" id="s_min" value="${esc(s.min_payout)}"></div>
      <div class="rate"><span>هزینه ارسال</span><input type="number" id="s_ship" value="${esc(s.shipping_fee)}"></div>
      <div class="rate"><span>سقف مجموع نرخ‌ها (صدم درصد: ۱۵۰۰ = ۱۵٪)</span><input type="number" id="s_cap" value="${esc(s.max_total_bps)}"></div>
      ${+s.hold_days < 7 ? '<p class="note" style="color:var(--warn)">⚠ مهلت مرجوعی کوتاه است (حالت آزمایشی). برای سایت واقعی مثلاً ۱۴ روز بگذارید.</p>' : ''}
      <button class="btn" style="width:100%" onclick="saveSettings()">ذخیره تنظیمات</button></div></div>`;
  },
  async users() {
    const list = await api('/admin/users');
    $('#adm').innerHTML = `<div class="box"><div class="tw"><table><tr><th>نام</th><th>ایمیل</th><th>نقش</th><th>معرف</th><th>مستقیم</th><th>خرید شخصی</th><th>وضعیت</th><th></th></tr>
      ${list.map(u => `<tr><td>${esc(u.name)}${u.is_affiliate ? ' 🤝' : ''}</td><td dir="ltr">${esc(u.email)}</td><td>${u.role}</td><td>${esc(u.sponsor || '—')}</td><td>${u.direct}</td><td>${fmt(u.own_sales)}</td>
      <td>${u.is_active ? '<span class="badge b-ok">فعال</span>' : '<span class="badge b-bad">تعلیق</span>'}</td>
      <td>${u.role === 'admin' ? '' : `<button class="sm ${u.is_active ? 'no' : 'ok'}" onclick="setActive(${u.id},${!u.is_active})">${u.is_active ? 'تعلیق' : 'فعال‌سازی'}</button>`}</td></tr>`).join('')}</table></div></div>`;
  },
  async flags() {
    const list = await api('/admin/flags');
    $('#adm').innerHTML = `<div class="box"><div class="tw"><table><tr><th>شدت</th><th>نوع</th><th>کاربر</th><th>جزئیات</th><th>وضعیت</th><th></th></tr>
      ${list.map(f => `<tr><td><span class="sev s-${f.severity[0]}"></span>${f.severity}</td><td>${esc(f.type)}</td><td>${esc(f.user_name || '—')}</td><td>${esc(f.detail)}</td><td>${f.status}</td>
      <td>${f.status === 'open' ? `<button class="sm" onclick="resolveFlag(${f.id})">بسته شد</button>` : ''}</td></tr>`).join('') || '<tr><td class="empty">پرچمی نیست</td></tr>'}</table></div></div>`;
  },
  async audit() {
    const list = await api('/admin/audit');
    $('#adm').innerHTML = `<div class="box"><ul class="audit">${list.map(a => `<li>${esc(a.admin || '—')}: <b>${esc(a.action)}</b> ${esc(a.detail)} <small>· ${date(a.created_at)}</small></li>`).join('')}</ul></div>`;
  },
};
const reload = () => admViews[admTab]();
window.deliver = act(async id => { await A(`/orders/${id}/deliver`); toast('ثبت شد'); reload(); });
window.refund = act(async (o, i) => { if (!confirm('این آیتم مرجوع شود؟')) return; await A(`/orders/${o}/refund`, 'POST', { item_id: i }); toast('مرجوع شد'); reload(); });
window.approveNow = act(async () => { const r = await A('/commissions/approve-due'); toast(`${fmt(r.approved)} پورسانت تأیید شد`); reload(); });
window.payout = act(async (id, a) => { await A(`/payouts/${id}/${a}`); reload(); });
window.setActive = act(async (id, v) => { await A(`/users/${id}/active`, 'POST', { active: v }); reload(); });
window.resolveFlag = act(async id => { await A(`/flags/${id}/resolve`); reload(); });
window.saveRules = act(async () => { await A('/rules', 'PUT', { rates: [...document.querySelectorAll('.rt')].map(e => Math.round(+e.value * 100)) }); toast('نرخ‌ها ذخیره شد'); reload(); });
window.saveSettings = act(async () => { await A('/settings', 'PUT', { hold_days: val('s_hold'), min_payout: val('s_min'), shipping_fee: val('s_ship'), max_total_bps: val('s_cap') }); toast('ذخیره شد'); reload(); });

/* ----- فرم محصول + آپلود عکس ----- */
window.editProduct = act(async id => {
  const p = id ? await api('/admin/products/' + id) : { name: '', sku: '', category: '', price: '', stock: 0, brief: '', description: '', usage_instructions: '', ingredients: '', commission_eligible: true, is_active: true, images: [] };
  const f = (k, label, type = 'text') => `<div><label>${label}</label><input type="${type}" id="f_${k}" value="${esc(p[k])}"></div>`;
  const t = (k, label) => `<label>${label}</label><textarea id="f_${k}">${esc(p[k])}</textarea>`;
  $('#pform').innerHTML = `<div class="sec"><h3>${id ? 'ویرایش محصول' : 'محصول جدید'}</h3>
    <div class="row2">${f('name', 'نام محصول')}${f('sku', 'کد کالا (یکتا)')}${f('category', 'دسته‌بندی')}${f('price', 'قیمت (افغانی)', 'number')}${f('stock', 'موجودی', 'number')}${f('brief', 'توضیح کوتاه')}</div>
    ${t('description', 'توضیحات کامل')}${t('usage_instructions', 'روش مصرف')}${t('ingredients', 'ترکیبات و اطلاعات')}
    <div class="chk"><input type="checkbox" id="f_commission_eligible" ${p.commission_eligible ? 'checked' : ''}><span>مشمول پورسانت</span></div>
    <div class="chk"><input type="checkbox" id="f_is_active" ${p.is_active ? 'checked' : ''}><span>نمایش در فروشگاه</span></div>
    <label>افزودن عکس (jpg / png / webp — تا ۸ فایل، هر کدام حداکثر ۵ مگابایت)</label><input type="file" id="f_files" accept="image/jpeg,image/png,image/webp" multiple>
    ${p.images.length ? `<div class="imgs">${p.images.map((i, k) => `<div><img src="${esc(i.url)}"><br>${k ? `<button class="sm" onclick="cover(${i.id},${id})">شاخص</button> ` : '<small>شاخص</small> '}<button class="sm no" onclick="delImg(${i.id},${id})">حذف</button></div>`).join('')}</div>` : ''}
    <button class="btn" onclick="saveProduct(${id})">ذخیره</button> <button class="btn ghost" onclick="$('#pform').innerHTML=''">بستن</button></div>`;
  $('#pform').scrollIntoView({ behavior: 'smooth' });
});
window.saveProduct = act(async id => {
  const b = {}; ['name', 'sku', 'category', 'price', 'stock', 'brief', 'description', 'usage_instructions', 'ingredients'].forEach(k => b[k] = val('f_' + k));
  b.commission_eligible = $('#f_commission_eligible').checked; b.is_active = $('#f_is_active').checked;
  const p = id ? await A('/products/' + id, 'PUT', b) : await A('/products', 'POST', b);
  const files = $('#f_files').files;
  if (files.length) { const fd = new FormData(); [...files].forEach(x => fd.append('images', x)); await api(`/admin/products/${p.id}/images`, { method: 'POST', body: fd }); }
  toast('محصول ذخیره شد'); await reload(); editProduct(p.id);
});
window.delImg = act(async (iid, pid) => { await A('/images/' + iid, 'DELETE'); editProduct(pid); reload(); });
window.cover = act(async (iid, pid) => { await A(`/images/${iid}/cover`); reload(); editProduct(pid); });
__EOF_FILE__
mkdir -p "$(dirname "public/index.html")"
cat > 'public/index.html' <<'__EOF_FILE__'
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>گل‌رخ | فروشگاه لوازم آرایشی و بهداشتی</title>
<link href="https://fonts.googleapis.com/css2?family=Vazirmatn:wght@400;500;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/style.css">
</head>
<body>
<header><div class="wrap nav">
  <a class="logo" href="#/">🌸 گل‌رخ</a>
  <div class="tabs" id="nav"></div>
</div></header>
<div class="wrap"><main id="app" style="padding:24px 0 48px"></main></div>
<footer>درآمد همکاری وابسته به فروش واقعی است و تضمین‌شده نیست · نسخه آزمایشی</footer>
<script src="/app.js"></script>
</body>
</html>
__EOF_FILE__
mkdir -p "$(dirname "public/style.css")"
cat > 'public/style.css' <<'__EOF_FILE__'

:root{--bg:#fff8f6;--card:#fff;--ink:#2b2226;--muted:#8a7a80;--brand:#d6577b;--brand2:#f4a6b8;--soft:#fde8ee;--ok:#2f9e6e;--warn:#d98a1c;--bad:#c94444;--line:#f1dfe3;--r:16px}
*{box-sizing:border-box;margin:0}
body{font-family:Vazirmatn,Tahoma,sans-serif;background:var(--bg);color:var(--ink);line-height:1.7}
a{color:inherit;text-decoration:none}
.wrap{max-width:1100px;margin:auto;padding:0 16px}
header{background:var(--card);border-bottom:1px solid var(--line);position:sticky;top:0;z-index:5}
.nav{display:flex;align-items:center;gap:12px;height:64px}
.logo{font-weight:700;font-size:20px;color:var(--brand)}
.tabs{display:flex;gap:4px;margin-inline-start:auto;overflow-x:auto}
.tab{border:0;background:none;font:inherit;padding:8px 14px;border-radius:99px;cursor:pointer;color:var(--muted);white-space:nowrap}
.tab.on{background:var(--soft);color:var(--brand);font-weight:700}
.cart{background:var(--brand);color:#fff;border-radius:99px;padding:6px 14px;font-size:14px;white-space:nowrap}
section.page{display:none;padding:24px 0 48px}section.page.on{display:block}
h2{font-size:20px;margin:8px 0 14px}
.hero{background:linear-gradient(120deg,var(--soft),#fff0d9);border-radius:24px;padding:40px 32px;display:flex;align-items:center;justify-content:space-between;gap:24px;flex-wrap:wrap}
.hero h1{font-size:30px;line-height:1.4;margin-bottom:8px}
.hero p{color:var(--muted);max-width:460px;margin-bottom:16px}
.btn{display:inline-block;border:0;font:inherit;background:var(--brand);color:#fff;padding:10px 22px;border-radius:12px;cursor:pointer;font-weight:500}
.btn.ghost{background:var(--soft);color:var(--brand)}
.blob{width:170px;height:170px;border-radius:50% 40% 55% 45%;background:radial-gradient(circle at 30% 30%,#fff,var(--brand2))}
.cats{display:flex;gap:10px;flex-wrap:wrap;margin:24px 0}
.chip{background:var(--card);border:1px solid var(--line);padding:6px 16px;border-radius:99px;font-size:14px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:16px}
.p{background:var(--card);border:1px solid var(--line);border-radius:var(--r);overflow:hidden;transition:.2s}
.p:hover{transform:translateY(-3px);box-shadow:0 8px 24px #d6577b22}
.ph{height:140px;display:grid;place-items:center;font-size:42px}
.pb{padding:12px 14px}.pb small{color:var(--muted)}
.price{display:flex;justify-content:space-between;align-items:center;margin-top:8px;font-weight:700}
.earn{display:flex;justify-content:space-between;align-items:center;margin-top:10px;background:var(--soft);color:var(--brand);border-radius:10px;padding:5px 10px;font-size:12px;cursor:pointer;border:0;width:100%;font-family:inherit}
.badge{display:inline-block;font-size:12px;padding:2px 10px;border-radius:99px}
.b-ok{background:#e2f6ec;color:var(--ok)}.b-warn{background:#fdf0da;color:var(--warn)}.b-bad{background:#fbe4e4;color:var(--bad)}
.box{background:var(--card);border:1px solid var(--line);border-radius:var(--r);padding:18px;margin-bottom:20px}
.cols{display:grid;grid-template-columns:repeat(auto-fit,minmax(310px,1fr));gap:20px}
.steps{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px;margin:24px 0}
.step{background:var(--card);border:1px solid var(--line);border-radius:var(--r);padding:20px;text-align:center}
.step .n{width:44px;height:44px;border-radius:50%;background:var(--brand);color:#fff;display:grid;place-items:center;margin:0 auto 10px;font-weight:700}
.step p{color:var(--muted);font-size:14px}
label{display:block;font-size:14px;margin:12px 0 4px;color:var(--muted)}
input[type=text],input[type=email],input[type=tel],input[type=password]{width:100%;font:inherit;padding:10px 12px;border:1px solid var(--line);border-radius:12px;background:var(--bg)}
input[type=range]{width:100%;accent-color:var(--brand)}
.rowv{display:flex;justify-content:space-between;font-size:14px}.rowv b{color:var(--brand)}
.res{background:var(--soft);border-radius:14px;padding:14px;margin-top:14px}
.res div{display:flex;justify-content:space-between;padding:3px 0;font-size:14px}
.res .tot{border-top:1px dashed var(--brand2);margin-top:6px;padding-top:8px;font-weight:700;font-size:17px;color:var(--brand)}
.sp{background:#e2f6ec;color:var(--ok);border-radius:10px;padding:8px 12px;font-size:14px;margin-top:6px}
.chk{display:flex;gap:8px;align-items:flex-start;margin:14px 0;font-size:13px;color:var(--muted)}
.note{font-size:13px;color:var(--muted);margin-top:10px}
.pledge{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:10px;margin-top:8px}
.pledge div{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:10px 14px;font-size:14px}
/* dashboard */
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:14px;margin-bottom:20px}
.stat{background:var(--card);border:1px solid var(--line);border-radius:var(--r);padding:16px}
.stat b{display:block;font-size:20px;margin-top:4px}.stat span{color:var(--muted);font-size:13px}
.link{display:flex;gap:8px;flex-wrap:wrap}
.link input{flex:1;min-width:200px;direction:ltr}
.rank{display:flex;align-items:center;gap:14px;margin-bottom:12px}
.medal{width:56px;height:56px;border-radius:50%;background:linear-gradient(135deg,#e8e8ec,#a9adb8);display:grid;place-items:center;font-size:26px;flex:none}
.bar{height:12px;background:var(--soft);border-radius:99px;overflow:hidden;margin:8px 0}
.bar i{display:block;height:100%;width:42%;background:linear-gradient(90deg,var(--brand2),var(--brand));border-radius:99px}
.tiers{display:flex;justify-content:space-between;font-size:12px;color:var(--muted)}
.tiers .on{color:var(--brand);font-weight:700}
ul.tree,ul.tree ul{list-style:none;padding:0;margin:0}
ul.tree ul{margin-inline-start:18px;border-inline-start:2px solid var(--line);padding-inline-start:12px}
.tree li{margin:6px 0}
.tree summary,.tree .leaf{display:flex;align-items:center;gap:10px;background:var(--bg);border:1px solid var(--line);border-radius:12px;padding:8px 12px;cursor:pointer;font-size:14px;list-style:none}
.tree summary::-webkit-details-marker{display:none}
.tree .nm{flex:1}.tree small{color:var(--muted)}
.dot{width:30px;height:30px;border-radius:50%;display:grid;place-items:center;color:#fff;font-size:12px;font-weight:700;flex:none}
.l0{background:var(--ink)}.l1{background:#d6577b}.l2{background:#e58aa3}.l3{background:#f0b3c3}
.chart{display:flex;align-items:flex-end;gap:12px;height:160px;margin-top:10px}
.chart div{flex:1;text-align:center;font-size:12px;color:var(--muted)}
.chart i{display:block;background:linear-gradient(0deg,var(--brand),var(--brand2));border-radius:8px 8px 0 0;margin-bottom:4px}
.tw{overflow-x:auto}
table{width:100%;border-collapse:collapse;font-size:14px;min-width:480px}
th,td{text-align:right;padding:9px 8px;border-bottom:1px solid var(--line)}th{color:var(--muted);font-weight:500}
.pos{color:var(--ok)}.neg{color:var(--bad)}
footer{text-align:center;color:var(--muted);font-size:13px;padding:24px}

.banner-ref{display:flex;align-items:center;gap:10px;background:#e2f6ec;color:var(--ok);border-radius:14px;padding:10px 16px;margin-bottom:16px;font-size:14px}
.sm{border:0;font:inherit;font-size:12px;padding:5px 12px;border-radius:9px;cursor:pointer;background:var(--soft);color:var(--brand)}
.sm.ok{background:#e2f6ec;color:var(--ok)}.sm.no{background:#fbe4e4;color:var(--bad)}
.banners{display:flex;gap:16px;flex-wrap:wrap;align-items:flex-end}
.bn{border-radius:14px;color:#fff;padding:14px;display:flex;flex-direction:column;justify-content:space-between;font-size:13px}
.bn b{font-size:16px;line-height:1.4}
.bn.a{width:130px;height:230px;background:linear-gradient(160deg,#d6577b,#f4a6b8)}
.bn.b{width:180px;height:180px;background:linear-gradient(135deg,#e58aa3,#f0b3c3)}
.bn.c{width:280px;height:158px;background:linear-gradient(120deg,#b94a6b,#d6577b)}
.bn small{opacity:.9}
.feed{list-style:none;padding:0}
.feed li{display:flex;gap:10px;padding:10px 0;border-bottom:1px dashed var(--line);font-size:14px}
.feed li small{color:var(--muted);display:block}
.ltr{direction:ltr;text-align:left;font-size:12px;color:var(--muted)}
input[type=number],select{font:inherit;padding:8px 10px;border:1px solid var(--line);border-radius:10px;background:var(--bg);width:100%}
.rate{display:grid;grid-template-columns:1fr 110px;gap:8px;align-items:center;margin:8px 0}
.capbox{border-radius:12px;padding:10px 14px;margin-top:10px;font-size:14px}
.capbox.ok{background:#e2f6ec;color:var(--ok)}.capbox.bad{background:#fbe4e4;color:var(--bad)}
.sev{display:inline-block;width:10px;height:10px;border-radius:50%;margin-inline-end:6px}
.s-h{background:var(--bad)}.s-m{background:var(--warn)}.s-l{background:#9bb0c4}
.mini{display:flex;align-items:center;gap:10px;font-size:13px;margin:8px 0}
.mini .bar{flex:1;margin:0}.mini .bar i{width:var(--w)}
.cartrow{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid var(--line)}
.cartrow .ic{width:56px;height:56px;border-radius:12px;display:grid;place-items:center;font-size:26px}
.cartrow div:nth-child(2){flex:1}
.sum div{display:flex;justify-content:space-between;padding:4px 0;font-size:14px}
.sum .t{border-top:1px solid var(--line);margin-top:6px;padding-top:10px;font-weight:700;font-size:17px}
.rc{display:flex;gap:8px}.rc input{flex:1;direction:ltr}

.atabs{display:flex;gap:6px;overflow-x:auto;margin-bottom:18px;padding-bottom:4px}
.atab{border:1px solid var(--line);background:var(--card);font:inherit;font-size:14px;padding:7px 16px;border-radius:99px;cursor:pointer;white-space:nowrap;color:var(--muted)}
.atab.on{background:var(--brand);border-color:var(--brand);color:#fff}
.apanel{display:none}.apanel.on{display:block}
.tools{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:12px}
.tools input,.tools select{flex:1;min-width:160px}
.alert{display:flex;align-items:center;gap:10px;padding:10px 0;border-bottom:1px dashed var(--line);font-size:14px}
.alert:last-child{border:0}.alert span:nth-child(2){flex:1}
.faq details{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:12px 16px;margin-bottom:10px}
.faq summary{cursor:pointer;font-weight:500}
.faq p,.faq ul{margin-top:8px;color:var(--muted);font-size:14px}.faq ul{padding-inline-start:20px}
.gloss{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:12px}
.gloss div{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:12px 14px;font-size:14px}
.gloss b{color:var(--brand)}
.warn{background:#fdf0da;color:#8a5a0a;border-radius:14px;padding:12px 16px;font-size:14px;margin-bottom:16px}
.audit{list-style:none;padding:0;font-size:13px}.audit li{padding:7px 0;border-bottom:1px dashed var(--line)}.audit small{color:var(--muted)}
.tools input[type=text]{width:auto}

/* ---- اضافه برای نسخه واقعی ---- */
.ph img{width:100%;height:100%;object-fit:cover}
.ph{overflow:hidden}
.gal{display:grid;grid-template-columns:1fr 1fr;gap:24px}
@media(max-width:760px){.gal{grid-template-columns:1fr}}
.gal .main{height:380px;border-radius:var(--r);overflow:hidden;background:var(--soft);display:grid;place-items:center;font-size:90px}
.gal .main img{width:100%;height:100%;object-fit:cover}
.thumbs{display:flex;gap:8px;margin-top:10px;flex-wrap:wrap}
.thumbs img{width:64px;height:64px;object-fit:cover;border-radius:10px;border:2px solid var(--line);cursor:pointer}
.thumbs img.on{border-color:var(--brand)}
.sec{background:var(--card);border:1px solid var(--line);border-radius:var(--r);padding:16px 18px;margin-top:14px}
.sec h3{font-size:16px;margin-bottom:6px;color:var(--brand)}
.qty{display:flex;align-items:center;gap:8px}
.qty button{width:30px;height:30px;border:0;border-radius:9px;background:var(--soft);color:var(--brand);font-size:18px;cursor:pointer}
textarea{width:100%;font:inherit;padding:10px 12px;border:1px solid var(--line);border-radius:12px;background:var(--bg);min-height:80px}
input[type=text],input[type=email],input[type=password],input[type=number],input[type=tel],select{width:100%;font:inherit;padding:10px 12px;border:1px solid var(--line);border-radius:12px;background:var(--bg)}
.row2{display:grid;grid-template-columns:1fr 1fr;gap:12px}
@media(max-width:600px){.row2{grid-template-columns:1fr}}
.toast{position:fixed;bottom:20px;inset-inline:0;margin:auto;width:max-content;max-width:90%;background:var(--ink);color:#fff;padding:10px 20px;border-radius:12px;z-index:50;font-size:14px}
.toast.err{background:var(--bad)}
.imgs{display:flex;gap:10px;flex-wrap:wrap;margin:10px 0}
.imgs div{width:92px;text-align:center;font-size:11px}
.imgs img{width:92px;height:92px;object-fit:cover;border-radius:10px;border:1px solid var(--line)}
.sm.no{background:#fbe4e4;color:var(--bad)}
.hdr-btn{border:0;background:none;font:inherit;cursor:pointer;color:var(--muted);padding:6px 10px}
.empty{text-align:center;color:var(--muted);padding:30px}
.code{direction:ltr;display:inline-block;background:var(--soft);padding:2px 10px;border-radius:8px;color:var(--brand)}
__EOF_FILE__
mkdir -p "$(dirname "src/config.ts")"
cat > 'src/config.ts' <<'__EOF_FILE__'
import 'dotenv/config';

export const PORT = Number(process.env.PORT ?? 3000);
export const JWT_SECRET = process.env.JWT_SECRET ?? 'dev-secret-change-me';
export const COOKIE_SECURE = process.env.COOKIE_SECURE === 'true';
export const REF_COOKIE_MS = 30 * 24 * 3600 * 1000; // لینک ارجاع ۳۰ روز در مرورگر می‌ماند

if (process.env.NODE_ENV === 'production' && JWT_SECRET.startsWith('change-me')) {
  throw new Error('JWT_SECRET must be set in production');
}
__EOF_FILE__
mkdir -p "$(dirname "src/db.ts")"
cat > 'src/db.ts' <<'__EOF_FILE__'
import 'dotenv/config';
import { Pool, PoolClient, types } from 'pg';

types.setTypeParser(20, Number);   // BIGINT → number
types.setTypeParser(1700, Number); // NUMERIC (SUM) → number

export const pool = new Pool({ connectionString: process.env.DATABASE_URL });
export type Tx = PoolClient;
export type Q = { query: (text: string, params?: any[]) => Promise<{ rows: any[]; rowCount: number | null }> };

export async function withTx<T>(fn: (tx: Tx) => Promise<T>): Promise<T> {
  const c = await pool.connect();
  try {
    await c.query('BEGIN');
    const r = await fn(c);
    await c.query('COMMIT');
    return r;
  } catch (e) {
    await c.query('ROLLBACK');
    throw e;
  } finally {
    c.release();
  }
}

export async function getSetting(db: Q, key: string, def: string): Promise<string> {
  const r = await db.query('SELECT value FROM settings WHERE key=$1', [key]);
  return r.rows[0]?.value ?? def;
}

export const audit = (db: Q, adminId: number, action: string, detail = '') =>
  db.query('INSERT INTO audit_log(admin_id,action,detail) VALUES ($1,$2,$3)', [adminId, action, detail]);

export const flag = (db: Q, type: string, severity: 'high' | 'medium' | 'low', userId: number | null, detail: string) =>
  db.query('INSERT INTO fraud_flags(type,severity,user_id,detail) VALUES ($1,$2,$3,$4)', [type, severity, userId, detail]);
__EOF_FILE__
mkdir -p "$(dirname "src/http.ts")"
cat > 'src/http.ts' <<'__EOF_FILE__'
import { Request, Response, RequestHandler } from 'express';

export class HttpError extends Error {
  constructor(public status: number, message: string) { super(message); }
}
export const wrap = (fn: (req: Request, res: Response) => Promise<unknown>): RequestHandler =>
  (req, res, next) => { fn(req, res).catch(next); };

export const num = (v: unknown, name: string, min = 0) => {
  const n = Number(v);
  if (!Number.isFinite(n) || n < min) throw new HttpError(400, `مقدار «${name}» نامعتبر است`);
  return Math.floor(n);
};
__EOF_FILE__
mkdir -p "$(dirname "src/middleware/auth.ts")"
cat > 'src/middleware/auth.ts' <<'__EOF_FILE__'
import { Request, Response, NextFunction, RequestHandler } from 'express';
import jwt from 'jsonwebtoken';
import { JWT_SECRET, COOKIE_SECURE } from '../config';
import { pool } from '../db';
import { HttpError } from '../http';

declare global {
  namespace Express { interface Request { user?: { id: number; role: string } } }
}

export const sign = (u: { id: number; role: string }) => jwt.sign(u, JWT_SECRET, { expiresIn: '30d' });

export const setAuthCookie = (res: Response, u: { id: number; role: string }) =>
  res.cookie('token', sign(u), { httpOnly: true, sameSite: 'lax', secure: COOKIE_SECURE, maxAge: 30 * 86400e3 });

export const loadUser = async (req: Request, _res: Response, next: NextFunction) => {
  try {
    const t = req.cookies?.token;
    if (t) {
      const p = jwt.verify(t, JWT_SECRET) as { id: number };
      const r = await pool.query('SELECT id, role FROM users WHERE id=$1 AND is_active', [p.id]);
      if (r.rows[0]) req.user = r.rows[0];
    }
  } catch { /* توکن نامعتبر = مهمان */ }
  next();
};

export const requireUser: RequestHandler = (req, _res, next) =>
  req.user ? next() : next(new HttpError(401, 'ابتدا وارد شوید'));

export const requireAdmin: RequestHandler = (req, _res, next) =>
  req.user?.role === 'admin' ? next() : next(new HttpError(403, 'دسترسی ندارید'));
__EOF_FILE__
mkdir -p "$(dirname "src/modules/admin/admin.routes.ts")"
cat > 'src/modules/admin/admin.routes.ts' <<'__EOF_FILE__'
import { Router } from 'express';
import { pool, withTx, audit, getSetting } from '../../db';
import { HttpError, wrap, num } from '../../http';
import { requireAdmin } from '../../middleware/auth';
import { adminRoutes as productAdmin } from '../catalog/catalog.routes';
import { approveDue, onDelivered, onOrderPaid, onRefund } from '../commission/commission.service';

const r = Router();
r.use(requireAdmin);
r.use(productAdmin); // /products, /images

const rows = async (sql: string, p: any[] = []) => (await pool.query(sql, p)).rows;

r.get('/stats', wrap(async (_req, res) => {
  res.json((await rows(`SELECT
    (SELECT COUNT(*)::int FROM users WHERE is_affiliate) AS affiliates,
    (SELECT COUNT(*)::int FROM users WHERE role='customer') AS customers,
    (SELECT COUNT(*)::int FROM orders) AS orders,
    (SELECT COALESCE(SUM(oi.net_amount-oi.refunded_amount),0) FROM order_items oi JOIN orders o ON o.id=oi.order_id
       WHERE o.status IN ('paid','delivered')) AS sales,
    (SELECT COALESCE(SUM(amount),0) FROM wallet_entries WHERE type='commission') AS commissions_approved,
    (SELECT COALESCE(SUM(amount),0) FROM commissions WHERE status='pending') AS commissions_pending,
    (SELECT COUNT(*)::int FROM payouts WHERE status='requested') AS payouts_open,
    (SELECT COUNT(*)::int FROM fraud_flags WHERE status='open') AS flags_open`))[0]);
}));

// ---------- سفارش‌ها
r.get('/orders', wrap(async (_req, res) => {
  res.json(await rows(
    `SELECT o.id, o.status, o.payment_method, o.total, o.created_at, o.address, o.phone, u.name AS buyer, s.name AS sponsor,
            (SELECT json_agg(json_build_object('id', oi.id, 'name', p.name, 'qty', oi.qty, 'net', oi.net_amount, 'refunded', oi.refunded_amount))
               FROM order_items oi JOIN products p ON p.id=oi.product_id WHERE oi.order_id=o.id) AS items,
            (SELECT COALESCE(SUM(amount),0) FROM commissions WHERE order_id=o.id AND status<>'reversed') AS commission_total
       FROM orders o JOIN users u ON u.id=o.buyer_id LEFT JOIN users s ON s.id=u.sponsor_id ORDER BY o.id DESC LIMIT 100`));
}));

r.post('/orders/:id/deliver', wrap(async (req, res) => {
  const id = num(req.params.id, 'id');
  await withTx(async tx => {
    const o = (await tx.query('SELECT * FROM orders WHERE id=$1 FOR UPDATE', [id])).rows[0];
    if (!o) throw new HttpError(404, 'سفارش پیدا نشد');
    if (o.status === 'pending') { // پرداخت در محل: پول هنگام تحویل دریافت می‌شود
      await tx.query(`UPDATE orders SET status='delivered', paid_at=now(), delivered_at=now() WHERE id=$1`, [id]);
      await onOrderPaid(id, tx);
    } else if (o.status === 'paid') {
      await tx.query(`UPDATE orders SET status='delivered', delivered_at=now() WHERE id=$1`, [id]);
      await onDelivered(id, tx);
    } else throw new HttpError(400, 'وضعیت این سفارش قابل تحویل نیست');
    await audit(tx, req.user!.id, 'order.deliver', String(id));
  });
  res.json({ ok: true });
}));

r.post('/orders/:id/refund', wrap(async (req, res) => {
  const id = num(req.params.id, 'id'), itemId = num(req.body?.item_id, 'آیتم', 1);
  await withTx(async tx => {
    const it = (await tx.query(
      `SELECT oi.*, o.status FROM order_items oi JOIN orders o ON o.id=oi.order_id WHERE oi.id=$1 AND oi.order_id=$2 FOR UPDATE OF oi`, [itemId, id])).rows[0];
    if (!it) throw new HttpError(404, 'آیتم پیدا نشد');
    const left = it.net_amount - it.refunded_amount;
    if (left <= 0) throw new HttpError(400, 'این آیتم قبلاً مرجوع شده است');
    await onRefund(itemId, left, tx);
    await tx.query('UPDATE products SET stock = stock + $2 WHERE id=$1', [it.product_id, it.qty]);
    const rest = await tx.query('SELECT 1 FROM order_items WHERE order_id=$1 AND net_amount - refunded_amount > 0', [id]);
    if (!rest.rowCount) await tx.query(`UPDATE orders SET status='refunded' WHERE id=$1`, [id]);
    await audit(tx, req.user!.id, 'order.refund', `order ${id} item ${itemId}`);
  });
  res.json({ ok: true });
}));

// ---------- پورسانت‌ها
r.get('/commissions', wrap(async (_req, res) => {
  res.json(await rows(
    `SELECT c.id, c.order_id, c.level, c.base_amount, c.rate_bps, c.amount, c.status, c.approve_after, u.name AS beneficiary
       FROM commissions c JOIN users u ON u.id=c.beneficiary_id ORDER BY c.id DESC LIMIT 200`));
}));

r.post('/commissions/approve-due', wrap(async (req, res) => {
  const n = await withTx(async tx => { const c = await approveDue(tx); await audit(tx, req.user!.id, 'commissions.approve', String(c)); return c; });
  res.json({ approved: n });
}));

// ---------- نرخ‌ها و تنظیمات
r.get('/rules', wrap(async (_req, res) => {
  const cur = await rows(
    `SELECT DISTINCT ON (level) level, rate_bps FROM commission_rules
      WHERE product_id IS NULL AND valid_from <= now() AND (valid_to IS NULL OR valid_to > now())
      ORDER BY level, valid_from DESC, id DESC`);
  const history = await rows(
    `SELECT level, rate_bps, valid_from, valid_to FROM commission_rules WHERE product_id IS NULL ORDER BY id DESC LIMIT 12`);
  res.json({ rates: [1, 2, 3].map(l => cur.find(c => c.level === l)?.rate_bps ?? 0), history,
             cap_bps: Number(await getSetting(pool, 'max_total_bps', '1500')) });
}));

r.put('/rules', wrap(async (req, res) => {
  const rates: number[] = (req.body?.rates ?? []).map((x: unknown) => num(x, 'نرخ'));
  if (rates.length !== 3 || rates.some(x => x > 10000)) throw new HttpError(400, 'نرخ سه سطح لازم است');
  await withTx(async tx => {
    const cap = Number(await getSetting(tx, 'max_total_bps', '1500'));
    if (rates.reduce((a, b) => a + b, 0) > cap) throw new HttpError(400, `مجموع نرخ‌ها نباید از ${cap / 100}٪ بیشتر شود`);
    await tx.query('UPDATE commission_rules SET valid_to=now() WHERE product_id IS NULL AND valid_to IS NULL');
    for (let l = 1; l <= 3; l++) await tx.query('INSERT INTO commission_rules(level,rate_bps) VALUES ($1,$2)', [l, rates[l - 1]]);
    await audit(tx, req.user!.id, 'rules.update', rates.map(x => x / 100 + '%').join(' / '));
  });
  res.json({ ok: true });
}));

const SETTING_KEYS = ['hold_days', 'min_payout', 'shipping_fee', 'max_total_bps'];
r.get('/settings', wrap(async (_req, res) => {
  const o: Record<string, string> = {};
  for (const r of await rows('SELECT key, value FROM settings')) o[r.key] = r.value;
  res.json(o);
}));
r.put('/settings', wrap(async (req, res) => {
  await withTx(async tx => {
    for (const k of SETTING_KEYS) {
      if (req.body?.[k] === undefined) continue;
      const v = num(req.body[k], k);
      await tx.query('INSERT INTO settings(key,value) VALUES ($1,$2) ON CONFLICT (key) DO UPDATE SET value=EXCLUDED.value', [k, String(v)]);
    }
    await audit(tx, req.user!.id, 'settings.update', JSON.stringify(req.body));
  });
  res.json({ ok: true });
}));

// ---------- برداشت‌ها
r.get('/payouts', wrap(async (_req, res) => {
  res.json(await rows(
    `SELECT p.*, u.name AS user_name,
            (SELECT COALESCE(SUM(amount),0) FROM wallet_entries WHERE user_id=p.user_id) AS balance
       FROM payouts p JOIN users u ON u.id=p.user_id ORDER BY (p.status='requested') DESC, p.id DESC LIMIT 100`));
}));
r.post('/payouts/:id/:action', wrap(async (req, res) => {
  const id = num(req.params.id, 'id'), approve = req.params.action === 'approve';
  if (!approve && req.params.action !== 'reject') throw new HttpError(400, 'عملیات نامعتبر');
  await withTx(async tx => {
    const p = (await tx.query('SELECT * FROM payouts WHERE id=$1 FOR UPDATE', [id])).rows[0];
    if (!p || p.status !== 'requested') throw new HttpError(400, 'این درخواست قابل بررسی نیست');
    await tx.query('UPDATE payouts SET status=$2 WHERE id=$1', [id, approve ? 'paid' : 'rejected']);
    if (!approve) await tx.query(`INSERT INTO wallet_entries(user_id,amount,type,ref_id) VALUES ($1,$2,'adjust',$3)`, [p.user_id, p.amount, id]);
    await audit(tx, req.user!.id, approve ? 'payout.approve' : 'payout.reject', String(id));
  });
  res.json({ ok: true });
}));

// ---------- همکاران و ضدتقلب
r.get('/users', wrap(async (req, res) => {
  const q = req.query.q ? `%${String(req.query.q)}%` : null;
  res.json(await rows(
    `SELECT u.id, u.name, u.email, u.role, u.is_affiliate, u.is_active, u.created_at, s.name AS sponsor,
            (SELECT COUNT(*)::int FROM users d WHERE d.sponsor_id=u.id) AS direct,
            (SELECT COALESCE(SUM(oi.net_amount-oi.refunded_amount),0) FROM order_items oi JOIN orders o ON o.id=oi.order_id
              WHERE o.buyer_id=u.id AND o.status IN ('paid','delivered')) AS own_sales
       FROM users u LEFT JOIN users s ON s.id=u.sponsor_id
      WHERE ($1::text IS NULL OR u.name ILIKE $1 OR u.email ILIKE $1) ORDER BY u.id DESC LIMIT 100`, [q]));
}));
r.post('/users/:id/active', wrap(async (req, res) => {
  const id = num(req.params.id, 'id');
  if (id === req.user!.id) throw new HttpError(400, 'نمی‌توانید حساب خودتان را تعلیق کنید');
  await pool.query('UPDATE users SET is_active=$2 WHERE id=$1', [id, !!req.body?.active]);
  await audit(pool, req.user!.id, req.body?.active ? 'user.activate' : 'user.suspend', String(id));
  res.json({ ok: true });
}));

r.get('/flags', wrap(async (_req, res) => {
  res.json(await rows(
    `SELECT f.*, u.name AS user_name FROM fraud_flags f LEFT JOIN users u ON u.id=f.user_id
      ORDER BY (f.status='open') DESC, f.id DESC LIMIT 100`));
}));
r.post('/flags/:id/resolve', wrap(async (req, res) => {
  await pool.query(`UPDATE fraud_flags SET status='resolved' WHERE id=$1`, [num(req.params.id, 'id')]);
  res.json({ ok: true });
}));

r.get('/audit', wrap(async (_req, res) => {
  res.json(await rows(`SELECT a.*, u.name AS admin FROM audit_log a LEFT JOIN users u ON u.id=a.admin_id ORDER BY a.id DESC LIMIT 100`));
}));

export default r;
__EOF_FILE__
mkdir -p "$(dirname "src/modules/affiliate/affiliate.routes.ts")"
cat > 'src/modules/affiliate/affiliate.routes.ts' <<'__EOF_FILE__'
import { Router } from 'express';
import { pool, withTx, getSetting } from '../../db';
import { HttpError, wrap, num } from '../../http';
import { requireUser } from '../../middleware/auth';

const r = Router();
r.use(requireUser);

const mask = (n: string) => (n ? n.trim().slice(0, 2) + '***' : '***');

r.get('/summary', wrap(async (req, res) => {
  const uid = req.user!.id;
  const u = (await pool.query('SELECT referral_code, is_affiliate FROM users WHERE id=$1', [uid])).rows[0];
  if (!u.is_affiliate) return res.json({ is_affiliate: false });

  const one = async (sql: string) => (await pool.query(sql, [uid])).rows[0];
  const money = await one(`SELECT
      (SELECT COALESCE(SUM(amount),0) FROM wallet_entries WHERE user_id=$1) AS balance,
      (SELECT COALESCE(SUM(amount),0) FROM commissions WHERE beneficiary_id=$1 AND status='pending') AS pending,
      (SELECT COALESCE(SUM(amount),0) FROM wallet_entries WHERE user_id=$1 AND type='commission') AS earned`);

  const lv = (await pool.query(
    `WITH RECURSIVE d AS (
       SELECT id, 1 AS lvl FROM users WHERE sponsor_id=$1
       UNION ALL SELECT u.id, d.lvl+1 FROM users u JOIN d ON u.sponsor_id=d.id WHERE d.lvl<3)
     SELECT lvl, COUNT(*)::int AS c FROM d GROUP BY lvl`, [uid])).rows;
  const network = [1, 2, 3].map(l => lv.find(x => x.lvl === l)?.c ?? 0);

  const tree = (await pool.query(
    `WITH RECURSIVE d AS (
       SELECT id, name, sponsor_id, 1 AS lvl FROM users WHERE sponsor_id=$1
       UNION ALL SELECT u.id, u.name, u.sponsor_id, d.lvl+1 FROM users u JOIN d ON u.sponsor_id=d.id WHERE d.lvl<3)
     SELECT d.id, d.name, d.sponsor_id, d.lvl,
            (SELECT COALESCE(SUM(oi.net_amount - oi.refunded_amount),0)
               FROM order_items oi JOIN orders o ON o.id=oi.order_id
              WHERE o.buyer_id=d.id AND o.status IN ('paid','delivered')) AS sales
       FROM d ORDER BY d.lvl, d.id`, [uid])).rows.map(t => ({ ...t, name: mask(t.name) }));

  const commissions = (await pool.query(
    `SELECT c.id, c.order_id, c.level, c.base_amount, c.rate_bps, c.amount, c.status, c.approve_after, c.created_at
       FROM commissions c WHERE beneficiary_id=$1 ORDER BY c.id DESC LIMIT 15`, [uid])).rows;
  const wallet = (await pool.query(
    'SELECT id, amount, type, created_at FROM wallet_entries WHERE user_id=$1 ORDER BY id DESC LIMIT 10', [uid])).rows;
  const payouts = (await pool.query(
    'SELECT id, amount, method, status, created_at FROM payouts WHERE user_id=$1 ORDER BY id DESC LIMIT 10', [uid])).rows;
  const min_payout = Number(await getSetting(pool, 'min_payout', '500'));

  res.json({ is_affiliate: true, referral_code: u.referral_code, ...money, network, tree, commissions, wallet, payouts, min_payout });
}));

r.post('/payouts', wrap(async (req, res) => {
  const amount = num(req.body?.amount, 'مبلغ', 1);
  const method = String(req.body?.method ?? '').trim(), account = String(req.body?.account ?? '').trim();
  if (!method || account.length < 3) throw new HttpError(400, 'روش و مشخصات حساب را وارد کنید');

  const id = await withTx(async tx => {
    const u = (await tx.query('SELECT is_affiliate FROM users WHERE id=$1 FOR UPDATE', [req.user!.id])).rows[0];
    if (!u.is_affiliate) throw new HttpError(403, 'شما همکار فروش نیستید');
    const min = Number(await getSetting(tx, 'min_payout', '500'));
    if (amount < min) throw new HttpError(400, `حداقل برداشت ${min} افغانی است`);
    const bal = (await tx.query('SELECT COALESCE(SUM(amount),0) AS b FROM wallet_entries WHERE user_id=$1', [req.user!.id])).rows[0].b;
    if (amount > bal) throw new HttpError(400, 'موجودی کافی نیست');
    const p = (await tx.query('INSERT INTO payouts(user_id,amount,method,account) VALUES ($1,$2,$3,$4) RETURNING id',
      [req.user!.id, amount, method, account])).rows[0];
    await tx.query(`INSERT INTO wallet_entries(user_id,amount,type,ref_id) VALUES ($1,$2,'payout',$3)`, [req.user!.id, -amount, p.id]);
    return p.id;
  });
  res.json({ id });
}));

export default r;
__EOF_FILE__
mkdir -p "$(dirname "src/modules/auth/auth.routes.ts")"
cat > 'src/modules/auth/auth.routes.ts' <<'__EOF_FILE__'
import { Router } from 'express';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { pool, withTx, flag } from '../../db';
import { HttpError, wrap } from '../../http';
import { requireUser, setAuthCookie } from '../../middleware/auth';

const r = Router();
const newCode = () => crypto.randomBytes(5).toString('hex').toUpperCase().slice(0, 8);
const pub = (u: any) => ({ id: u.id, name: u.name, email: u.email, role: u.role, is_affiliate: u.is_affiliate, referral_code: u.referral_code });

r.post('/register', wrap(async (req, res) => {
  const { name, email, password, ref } = req.body ?? {};
  if (typeof name !== 'string' || name.trim().length < 2) throw new HttpError(400, 'نام را وارد کنید');
  if (typeof email !== 'string' || !/^\S+@\S+\.\S+$/.test(email)) throw new HttpError(400, 'ایمیل نامعتبر است');
  if (typeof password !== 'string' || password.length < 8) throw new HttpError(400, 'رمز عبور حداقل ۸ کاراکتر باشد');

  const refCode = String(ref || req.cookies?.ref || '').trim().toUpperCase();
  const hash = await bcrypt.hash(password, 10);

  const user = await withTx(async tx => {
    let sponsor: number | null = null;
    if (refCode) {
      const s = await tx.query('SELECT id FROM users WHERE referral_code=$1 AND is_active', [refCode]);
      sponsor = s.rows[0]?.id ?? null;
    }
    let u;
    try {
      u = (await tx.query(
        `INSERT INTO users(name,email,password_hash,referral_code,sponsor_id,signup_ip)
         VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
        [name.trim(), email.trim().toLowerCase(), hash, newCode(), sponsor, req.ip ?? null])).rows[0];
    } catch (e: any) {
      if (e.code === '23505') throw new HttpError(409, 'این ایمیل قبلاً ثبت شده است');
      throw e;
    }
    if (req.ip) {
      const c = await tx.query(
        `SELECT COUNT(*)::int AS c FROM users WHERE signup_ip=$1 AND created_at > now() - interval '24 hours'`, [req.ip]);
      if (c.rows[0].c >= 3) await flag(tx, 'duplicate_ip', 'medium', u.id, `${c.rows[0].c} حساب با یک IP در ۲۴ ساعت`);
    }
    return u;
  });

  setAuthCookie(res, user);
  res.json(pub(user));
}));

r.post('/login', wrap(async (req, res) => {
  const { email, password } = req.body ?? {};
  const u = (await pool.query('SELECT * FROM users WHERE email=$1', [String(email ?? '').trim().toLowerCase()])).rows[0];
  if (!u || !(await bcrypt.compare(String(password ?? ''), u.password_hash))) throw new HttpError(401, 'ایمیل یا رمز عبور اشتباه است');
  if (!u.is_active) throw new HttpError(403, 'حساب شما تعلیق شده است');
  setAuthCookie(res, u);
  res.json(pub(u));
}));

r.post('/logout', (_req, res) => { res.clearCookie('token'); res.json({ ok: true }); });

r.get('/me', wrap(async (req, res) => {
  if (!req.user) return res.json(null);
  const u = (await pool.query(
    `SELECT u.*, s.name AS sponsor_name FROM users u LEFT JOIN users s ON s.id=u.sponsor_id WHERE u.id=$1`, [req.user.id])).rows[0];
  res.json({ ...pub(u), sponsor_name: u.sponsor_name });
}));

// نام معرفی که کوکی ۳۰ روزه‌اش در مرورگر هست
r.get('/referrer', wrap(async (req, res) => {
  const code = String(req.cookies?.ref ?? '');
  const s = code ? (await pool.query('SELECT name FROM users WHERE referral_code=$1 AND is_active', [code])).rows[0] : null;
  res.json({ name: s?.name ?? null, code: s ? code : null });
}));

r.post('/affiliate/join', requireUser, wrap(async (req, res) => {
  await pool.query('UPDATE users SET is_affiliate=true WHERE id=$1', [req.user!.id]);
  res.json({ ok: true });
}));

export default r;
__EOF_FILE__
mkdir -p "$(dirname "src/modules/catalog/catalog.routes.ts")"
cat > 'src/modules/catalog/catalog.routes.ts' <<'__EOF_FILE__'
import { Router } from 'express';
import multer from 'multer';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { pool, audit, getSetting } from '../../db';
import { HttpError, wrap, num } from '../../http';
import { requireAdmin } from '../../middleware/auth';

export const UPLOAD_DIR = path.join(process.cwd(), 'uploads');
fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const EXT: Record<string, string> = { 'image/jpeg': '.jpg', 'image/png': '.png', 'image/webp': '.webp' };
const upload = multer({
  storage: multer.diskStorage({
    destination: UPLOAD_DIR,
    filename: (_r, f, cb) => cb(null, crypto.randomBytes(8).toString('hex') + EXT[f.mimetype]),
  }),
  limits: { fileSize: 5 * 1024 * 1024, files: 8 },
  fileFilter: (_r, f, cb) => cb(null, f.mimetype in EXT),
});

// ---------- عمومی
export const publicRoutes = Router();

publicRoutes.get('/shipping', wrap(async (_req, res) => {
  res.json({ shipping_fee: Number(await getSetting(pool, 'shipping_fee', '0')) });
}));

publicRoutes.get('/categories', wrap(async (_req, res) => {
  res.json((await pool.query('SELECT DISTINCT category FROM products WHERE is_active ORDER BY 1')).rows.map(r => r.category));
}));

publicRoutes.get('/products', wrap(async (req, res) => {
  const cat = req.query.category ? String(req.query.category) : null;
  const rows = (await pool.query(
    `SELECT p.id, p.name, p.category, p.brief, p.price, p.stock,
            (SELECT url FROM product_images WHERE product_id=p.id ORDER BY sort, id LIMIT 1) AS image
       FROM products p WHERE p.is_active AND ($1::text IS NULL OR p.category=$1) ORDER BY p.id DESC`, [cat])).rows;
  res.json(rows);
}));

publicRoutes.get('/products/:id', wrap(async (req, res) => {
  const p = (await pool.query('SELECT * FROM products WHERE id=$1 AND is_active', [num(req.params.id, 'id')])).rows[0];
  if (!p) throw new HttpError(404, 'محصول پیدا نشد');
  p.images = (await pool.query('SELECT id, url FROM product_images WHERE product_id=$1 ORDER BY sort, id', [p.id])).rows;
  res.json(p);
}));

// ---------- مدیریت محصول (ادمین)
export const adminRoutes = Router();
adminRoutes.use(requireAdmin);

const TEXT = ['sku', 'name', 'category', 'brief', 'description', 'usage_instructions', 'ingredients'] as const;

function readBody(b: any, partial: boolean) {
  const out: Record<string, unknown> = {};
  for (const k of TEXT) if (b[k] !== undefined) out[k] = String(b[k]).trim();
  if (b.price !== undefined) out.price = num(b.price, 'قیمت');
  if (b.stock !== undefined) out.stock = num(b.stock, 'موجودی');
  if (b.commission_eligible !== undefined) out.commission_eligible = !!b.commission_eligible;
  if (b.is_active !== undefined) out.is_active = !!b.is_active;
  if (!partial && (!out.name || !out.sku || out.price === undefined)) throw new HttpError(400, 'نام، کد کالا و قیمت الزامی است');
  return out;
}

adminRoutes.get('/products', wrap(async (_req, res) => {
  res.json((await pool.query(
    `SELECT p.*, (SELECT COUNT(*)::int FROM product_images WHERE product_id=p.id) AS image_count,
            (SELECT url FROM product_images WHERE product_id=p.id ORDER BY sort, id LIMIT 1) AS image
       FROM products p ORDER BY p.id DESC`)).rows);
}));

adminRoutes.get('/products/:id', wrap(async (req, res) => {
  const p = (await pool.query('SELECT * FROM products WHERE id=$1', [num(req.params.id, 'id')])).rows[0];
  if (!p) throw new HttpError(404, 'محصول پیدا نشد');
  p.images = (await pool.query('SELECT id, url FROM product_images WHERE product_id=$1 ORDER BY sort, id', [p.id])).rows;
  res.json(p);
}));

adminRoutes.post('/products', wrap(async (req, res) => {
  const d = readBody(req.body ?? {}, false);
  const cols = Object.keys(d);
  try {
    const r = await pool.query(
      `INSERT INTO products(${cols.join(',')}) VALUES (${cols.map((_, i) => '$' + (i + 1)).join(',')}) RETURNING *`, Object.values(d));
    await audit(pool, req.user!.id, 'product.create', r.rows[0].name);
    res.json(r.rows[0]);
  } catch (e: any) {
    if (e.code === '23505') throw new HttpError(409, 'این کد کالا قبلاً ثبت شده است');
    throw e;
  }
}));

adminRoutes.put('/products/:id', wrap(async (req, res) => {
  const d = readBody(req.body ?? {}, true);
  const cols = Object.keys(d);
  if (!cols.length) throw new HttpError(400, 'چیزی برای ویرایش نیست');
  const r = await pool.query(
    `UPDATE products SET ${cols.map((c, i) => `${c}=$${i + 2}`).join(',')} WHERE id=$1 RETURNING *`,
    [num(req.params.id, 'id'), ...Object.values(d)]);
  if (!r.rows[0]) throw new HttpError(404, 'محصول پیدا نشد');
  await audit(pool, req.user!.id, 'product.update', r.rows[0].name);
  res.json(r.rows[0]);
}));

// حذف = غیرفعال‌سازی (سفارش‌های قبلی به محصول وابسته‌اند)
adminRoutes.delete('/products/:id', wrap(async (req, res) => {
  await pool.query('UPDATE products SET is_active=false WHERE id=$1', [num(req.params.id, 'id')]);
  await audit(pool, req.user!.id, 'product.deactivate', String(req.params.id));
  res.json({ ok: true });
}));

adminRoutes.post('/products/:id/images', upload.array('images', 8), wrap(async (req, res) => {
  const id = num(req.params.id, 'id');
  const files = (req.files as Express.Multer.File[]) ?? [];
  if (!files.length) throw new HttpError(400, 'فایل تصویر (jpg/png/webp تا ۵ مگابایت) انتخاب نشده است');
  let sort = (await pool.query('SELECT COALESCE(MAX(sort),0)+1 AS s FROM product_images WHERE product_id=$1', [id])).rows[0].s;
  for (const f of files) {
    await pool.query('INSERT INTO product_images(product_id,url,sort) VALUES ($1,$2,$3)', [id, '/uploads/' + f.filename, sort++]);
  }
  await audit(pool, req.user!.id, 'product.images.add', `${id} (+${files.length})`);
  res.json({ added: files.length });
}));

adminRoutes.post('/images/:id/cover', wrap(async (req, res) => {
  await pool.query(
    `UPDATE product_images SET sort = (SELECT COALESCE(MIN(sort),0)-1 FROM product_images
       WHERE product_id=(SELECT product_id FROM product_images WHERE id=$1)) WHERE id=$1`, [num(req.params.id, 'id')]);
  res.json({ ok: true });
}));

adminRoutes.delete('/images/:id', wrap(async (req, res) => {
  const r = await pool.query('DELETE FROM product_images WHERE id=$1 RETURNING url', [num(req.params.id, 'id')]);
  const url: string | undefined = r.rows[0]?.url;
  if (url?.startsWith('/uploads/')) fs.promises.unlink(path.join(UPLOAD_DIR, path.basename(url))).catch(() => {});
  res.json({ ok: true });
}));
__EOF_FILE__
mkdir -p "$(dirname "src/modules/commission/commission.repo.ts")"
cat > 'src/modules/commission/commission.repo.ts' <<'__EOF_FILE__'
import { Tx } from '../../db';

export interface Ancestor { beneficiary_id: number; lvl: number; is_affiliate: boolean; is_active: boolean }
export interface ItemRow { id: number; product_id: number; net_amount: number; refunded_amount: number; commission_eligible: boolean }

export const getOrder = async (tx: Tx, id: number) =>
  (await tx.query('SELECT * FROM orders WHERE id=$1 FOR UPDATE', [id])).rows[0];

export const getItems = async (tx: Tx, orderId: number): Promise<ItemRow[]> =>
  (await tx.query(
    `SELECT oi.id, oi.product_id, oi.net_amount, oi.refunded_amount, p.commission_eligible
       FROM order_items oi JOIN products p ON p.id = oi.product_id WHERE oi.order_id=$1`, [orderId])).rows;

export const getAncestors = async (tx: Tx, buyerId: number): Promise<Ancestor[]> =>
  (await tx.query(
    `WITH RECURSIVE up AS (
       SELECT id, sponsor_id, 0 AS lvl FROM users WHERE id = $1
       UNION ALL
       SELECT u.id, u.sponsor_id, up.lvl + 1 FROM users u JOIN up ON u.id = up.sponsor_id WHERE up.lvl < 3
     )
     SELECT up.id AS beneficiary_id, up.lvl, u.is_affiliate, u.is_active
       FROM up JOIN users u ON u.id = up.id WHERE up.lvl BETWEEN 1 AND 3 ORDER BY up.lvl`, [buyerId])).rows;

export const getRate = async (tx: Tx, level: number, productId: number): Promise<number> => {
  const r = await tx.query(
    `SELECT rate_bps FROM commission_rules
      WHERE level=$1 AND (product_id=$2 OR product_id IS NULL)
        AND valid_from <= now() AND (valid_to IS NULL OR valid_to > now())
      ORDER BY product_id NULLS LAST, valid_from DESC, id DESC LIMIT 1`, [level, productId]);
  return r.rows[0]?.rate_bps ?? 0;
};

export const insertCommission = (tx: Tx, c: {
  order_id: number; order_item_id: number; beneficiary_id: number; level: number;
  base_amount: number; rate_bps: number; amount: number; approve_after: string | Date;
}) => tx.query(
  `INSERT INTO commissions(order_id,order_item_id,beneficiary_id,level,base_amount,rate_bps,amount,approve_after)
   VALUES ($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT DO NOTHING`,
  [c.order_id, c.order_item_id, c.beneficiary_id, c.level, c.base_amount, c.rate_bps, c.amount, c.approve_after]);

export const lockDue = async (tx: Tx) =>
  (await tx.query(
    `SELECT id, beneficiary_id, amount FROM commissions
      WHERE status='pending' AND approve_after <= now() FOR UPDATE SKIP LOCKED`)).rows;

export const setStatus = (tx: Tx, id: number, status: string) =>
  tx.query('UPDATE commissions SET status=$2 WHERE id=$1', [id, status]);

export const walletInsert = (tx: Tx, userId: number, amount: number, type: string, refId: number) =>
  tx.query('INSERT INTO wallet_entries(user_id,amount,type,ref_id) VALUES ($1,$2,$3,$4) ON CONFLICT DO NOTHING',
    [userId, amount, type, refId]);

export const commissionsOfItem = async (tx: Tx, itemId: number) =>
  (await tx.query(
    `SELECT id, beneficiary_id, base_amount, rate_bps, amount, status
       FROM commissions WHERE order_item_id=$1 FOR UPDATE`, [itemId])).rows;

export const updateAmount = (tx: Tx, id: number, base: number, amount: number) =>
  tx.query(
    `UPDATE commissions SET base_amount=$2::bigint, amount=$3::bigint,
            status = CASE WHEN $3::bigint <= 0 THEN 'reversed' ELSE status END WHERE id=$1`, [id, base, amount]);

export const addRefund = (tx: Tx, itemId: number, amount: number) =>
  tx.query('UPDATE order_items SET refunded_amount = refunded_amount + $2 WHERE id=$1', [itemId, amount]);

export const rescheduleOrder = (tx: Tx, orderId: number, days: number) =>
  tx.query(
    `UPDATE commissions SET approve_after = now() + make_interval(days => $2)
      WHERE order_id=$1 AND status='pending'`, [orderId, days]);
__EOF_FILE__
mkdir -p "$(dirname "src/modules/commission/commission.service.ts")"
cat > 'src/modules/commission/commission.service.ts' <<'__EOF_FILE__'
import { Tx, getSetting } from '../../db';
import * as repo from './commission.repo';

const bps = (base: number, rate: number) => Math.floor((base * rate) / 10_000);

export const holdDays = async (tx: Tx) => Number(await getSetting(tx, 'hold_days', '14'));

/** بعد از پرداخت قطعی سفارش: ساخت پورسانت‌های pending (ایدمپوتنت). تا قبل از تحویل، approve_after = infinity */
export async function onOrderPaid(orderId: number, tx: Tx) {
  const order = await repo.getOrder(tx, orderId);
  if (!order || !['paid', 'delivered'].includes(order.status)) return;

  const items = (await repo.getItems(tx, orderId)).filter(i => i.commission_eligible);
  const chain = (await repo.getAncestors(tx, order.buyer_id))
    .filter(a => a.beneficiary_id !== order.buyer_id && a.is_affiliate && a.is_active);

  const approveAfter = order.delivered_at
    ? new Date(new Date(order.delivered_at).getTime() + (await holdDays(tx)) * 86_400_000)
    : 'infinity';

  for (const item of items) {
    const base = item.net_amount - item.refunded_amount;
    for (const { beneficiary_id, lvl } of chain) {
      const rate = await repo.getRate(tx, lvl, item.product_id);
      const amount = bps(base, rate);
      if (amount <= 0) continue;
      await repo.insertCommission(tx, {
        order_id: orderId, order_item_id: item.id, beneficiary_id,
        level: lvl, base_amount: base, rate_bps: rate, amount, approve_after: approveAfter,
      });
    }
  }
}

/** بعد از تحویل: شروع مهلت مرجوعی */
export async function onDelivered(orderId: number, tx: Tx) {
  await repo.rescheduleOrder(tx, orderId, await holdDays(tx));
}

export async function approveDue(tx: Tx) {
  const due = await repo.lockDue(tx);
  for (const c of due) {
    await repo.setStatus(tx, c.id, 'approved');
    await repo.walletInsert(tx, c.beneficiary_id, c.amount, 'commission', c.id);
  }
  return due.length;
}

export async function onRefund(orderItemId: number, refundAmount: number, tx: Tx) {
  await repo.addRefund(tx, orderItemId, refundAmount);
  for (const c of await repo.commissionsOfItem(tx, orderItemId)) {
    if (c.status === 'reversed') continue;
    const newBase = Math.max(c.base_amount - refundAmount, 0);
    const newAmount = bps(newBase, c.rate_bps);
    const delta = c.amount - newAmount;
    if (c.status === 'pending') {
      await repo.updateAmount(tx, c.id, newBase, newAmount);
    } else if (delta > 0) {
      await repo.walletInsert(tx, c.beneficiary_id, -delta, 'clawback', c.id);
      await repo.updateAmount(tx, c.id, newBase, newAmount);
    }
  }
}
__EOF_FILE__
mkdir -p "$(dirname "src/modules/orders/orders.routes.ts")"
cat > 'src/modules/orders/orders.routes.ts' <<'__EOF_FILE__'
import { Router } from 'express';
import { pool, withTx, getSetting, flag } from '../../db';
import { HttpError, wrap, num } from '../../http';
import { requireUser } from '../../middleware/auth';
import { onOrderPaid } from '../commission/commission.service';

const r = Router();
r.use(requireUser);

r.post('/', wrap(async (req, res) => {
  const { items, address, phone, refCode, payment_method } = req.body ?? {};
  if (!Array.isArray(items) || !items.length) throw new HttpError(400, 'سبد خرید خالی است');
  if (typeof address !== 'string' || address.trim().length < 5) throw new HttpError(400, 'آدرس را وارد کنید');
  if (typeof phone !== 'string' || phone.trim().length < 7) throw new HttpError(400, 'شماره تماس را وارد کنید');
  const method = payment_method === 'cod' ? 'cod' : 'online_test';

  // یکی‌کردن ردیف‌های تکراری
  const qty = new Map<number, number>();
  for (const it of items) {
    const id = num(it.product_id, 'محصول', 1), q = num(it.qty, 'تعداد', 1);
    if (q > 50) throw new HttpError(400, 'حداکثر تعداد هر محصول ۵۰ است');
    qty.set(id, (qty.get(id) ?? 0) + q);
  }

  const out = await withTx(async tx => {
    const buyer = (await tx.query('SELECT id, referral_code, sponsor_id FROM users WHERE id=$1 FOR UPDATE', [req.user!.id])).rows[0];

    // کد معرف: فقط برای خریدار بدون معرف و قبل از اولین خرید قطعی
    const code = String(refCode || req.cookies?.ref || '').trim().toUpperCase();
    if (code) {
      if (code === buyer.referral_code) {
        await flag(tx, 'self_referral', 'high', buyer.id, 'تلاش برای استفاده از کد معرف خود');
      } else if (!buyer.sponsor_id) {
        const prev = await tx.query(`SELECT 1 FROM orders WHERE buyer_id=$1 AND status IN ('paid','delivered')`, [buyer.id]);
        const sp = (await tx.query('SELECT id FROM users WHERE referral_code=$1 AND is_active', [code])).rows[0];
        if (!prev.rowCount && sp) {
          const cyc = await tx.query(
            `WITH RECURSIVE a AS (
               SELECT id, sponsor_id FROM users WHERE id=$1
               UNION ALL SELECT u.id, u.sponsor_id FROM users u JOIN a ON u.id=a.sponsor_id)
             SELECT 1 FROM a WHERE id=$2`, [sp.id, buyer.id]);
          if (!cyc.rowCount) await tx.query('UPDATE users SET sponsor_id=$2 WHERE id=$1', [buyer.id, sp.id]);
        }
      }
    }

    const products = (await tx.query('SELECT id, name, price FROM products WHERE id = ANY($1) AND is_active', [[...qty.keys()]])).rows;
    if (products.length !== qty.size) throw new HttpError(400, 'یکی از محصولات موجود نیست');

    const shipping = Number(await getSetting(tx, 'shipping_fee', '0'));
    const lines = products.map((p: any) => ({ id: p.id, name: p.name, q: qty.get(p.id)!, net: p.price * qty.get(p.id)! }));
    const total = lines.reduce((a, l) => a + l.net, 0) + shipping;

    const paid = method === 'online_test'; // در نسخه آزمایشی پرداخت آنلاین بلافاصله موفق فرض می‌شود
    const o = (await tx.query(
      `INSERT INTO orders(buyer_id,status,payment_method,address,phone,paid_at,shipping,total)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
      [buyer.id, paid ? 'paid' : 'pending', method, address.trim(), phone.trim(), paid ? new Date() : null, shipping, total])).rows[0];

    for (const l of lines) {
      const st = await tx.query('UPDATE products SET stock = stock - $2 WHERE id=$1 AND stock >= $2', [l.id, l.q]);
      if (!st.rowCount) throw new HttpError(400, `موجودی «${l.name}» کافی نیست`);
      await tx.query('INSERT INTO order_items(order_id,product_id,qty,net_amount) VALUES ($1,$2,$3,$4)', [o.id, l.id, l.q, l.net]);
    }
    if (paid) await onOrderPaid(o.id, tx);
    return { id: o.id, total, status: paid ? 'paid' : 'pending' };
  });
  res.json(out);
}));

r.get('/mine', wrap(async (req, res) => {
  res.json((await pool.query(
    `SELECT o.id, o.status, o.total, o.created_at,
            (SELECT json_agg(json_build_object('name', p.name, 'qty', oi.qty, 'net', oi.net_amount))
               FROM order_items oi JOIN products p ON p.id=oi.product_id WHERE oi.order_id=o.id) AS items
       FROM orders o WHERE o.buyer_id=$1 ORDER BY o.id DESC`, [req.user!.id])).rows);
}));

export default r;
__EOF_FILE__
mkdir -p "$(dirname "src/scripts/approve.ts")"
cat > 'src/scripts/approve.ts' <<'__EOF_FILE__'
import { pool, withTx } from '../db';
import { approveDue } from '../modules/commission/commission.service';

withTx(approveDue).then(n => console.log('approved:', n)).finally(() => pool.end());
__EOF_FILE__
mkdir -p "$(dirname "src/scripts/migrate.ts")"
cat > 'src/scripts/migrate.ts' <<'__EOF_FILE__'
import { readdirSync, readFileSync } from 'fs';
import { join } from 'path';
import { pool, withTx } from '../db';

(async () => {
  await pool.query('CREATE TABLE IF NOT EXISTS schema_migrations (name TEXT PRIMARY KEY)');
  const dir = join(process.cwd(), 'migrations');
  for (const f of readdirSync(dir).filter(f => f.endsWith('.sql')).sort()) {
    if ((await pool.query('SELECT 1 FROM schema_migrations WHERE name=$1', [f])).rowCount) continue;
    await withTx(async tx => {
      await tx.query(readFileSync(join(dir, f), 'utf8'));
      await tx.query('INSERT INTO schema_migrations(name) VALUES ($1)', [f]);
    });
    console.log('applied', f);
  }
  await pool.end();
})().catch(e => { console.error(e); process.exit(1); });
__EOF_FILE__
mkdir -p "$(dirname "src/scripts/seed.ts")"
cat > 'src/scripts/seed.ts' <<'__EOF_FILE__'
import bcrypt from 'bcryptjs';
import { writeFileSync, mkdirSync } from 'fs';
import { join } from 'path';
import { pool } from '../db';

const ADMIN_EMAIL = process.env.SEED_ADMIN_EMAIL ?? 'admin@example.com';
const ADMIN_PASS = process.env.SEED_ADMIN_PASSWORD ?? 'Admin12345';
const DEMO_PASS = 'Test12345';

const products = [
  { sku: 'CR-001', name: 'کرم مرطوب‌کننده', category: 'مراقبت پوست', price: 480, stock: 50, emoji: '🧴', bg: '#fde8ee',
    brief: 'مرطوب‌کننده سبک برای استفاده روزانه',
    description: 'کرم مرطوب‌کننده با بافت سبک که به‌سرعت جذب پوست می‌شود و تا ۲۴ ساعت نرمی را حفظ می‌کند.',
    usage: 'هر صبح و شب بعد از شستن صورت، مقدار کمی کرم را روی پوست پخش و ماساژ دهید.\nاز تماس با چشم خودداری کنید.',
    ingredients: 'آب، گلیسیرین، روغن جوجوبا، ویتامین E، عصاره آلوورا' },
  { sku: 'LP-002', name: 'رژ لب مات', category: 'آرایش', price: 320, stock: 80, emoji: '💄', bg: '#fbe0e0',
    brief: 'ماندگاری بالا، بدون خشکی',
    description: 'رژ لب مات با رنگدانه بالا و فرمول مرطوب‌کننده.',
    usage: 'ابتدا لب‌ها را تمیز کنید، سپس از وسط لب شروع کرده و به گوشه‌ها بکشید.',
    ingredients: 'موم، روغن کرچک، رنگدانه‌های معدنی، ویتامین E' },
  { sku: 'SR-003', name: 'سرم ویتامین C', category: 'مراقبت پوست', price: 790, stock: 30, emoji: '💧', bg: '#fff0d9',
    brief: 'روشن‌کننده و ضد لکه',
    description: 'سرم ویتامین C با غلظت ۱۰٪ برای شفافیت و یکنواختی رنگ پوست.',
    usage: 'شب‌ها ۳ تا ۴ قطره روی پوست تمیز بزنید. روز بعد حتماً از ضدآفتاب استفاده کنید.',
    ingredients: 'آب، ویتامین C (۱۰٪)، هیالورونیک اسید، ویتامین E' },
  { sku: 'SH-004', name: 'شامپو ترمیم‌کننده', category: 'مو', price: 290, stock: 60, emoji: '🧼', bg: '#e6f3fb',
    brief: 'مناسب موهای آسیب‌دیده و رنگ‌شده',
    description: 'شامپو بدون سولفات با کراتین برای ترمیم و براقی مو.',
    usage: 'روی موی مرطوب ماساژ دهید، ۲ دقیقه بماند و کامل آبکشی کنید.',
    ingredients: 'آب، کراتین، پروتئین ابریشم، روغن آرگان' },
  { sku: 'SS-005', name: 'کرم ضدآفتاب SPF50', category: 'مراقبت پوست', price: 560, stock: 45, emoji: '☀️', bg: '#fff6d6',
    brief: 'محافظت وسیع‌الطیف، بدون چربی',
    description: 'ضدآفتاب سبک با محافظت UVA/UVB، مناسب زیر آرایش.',
    usage: '۱۵ دقیقه قبل از خروج از خانه بزنید و هر ۲ تا ۳ ساعت تجدید کنید.',
    ingredients: 'فیلترهای UV، آب، گلیسیرین، ویتامین E' },
  { sku: 'MK-006', name: 'ماسک صورت', category: 'مراقبت پوست', price: 180, stock: 100, emoji: '🌿', bg: '#e4f4e8',
    brief: 'آبرسان و آرام‌بخش',
    description: 'ماسک ورقه‌ای با عصاره چای سبز برای آبرسانی سریع.',
    usage: 'روی پوست تمیز بگذارید، ۱۵ تا ۲۰ دقیقه صبر کنید و بردارید. نیازی به شستن نیست.',
    ingredients: 'عصاره چای سبز، هیالورونیک اسید، آب' },
  { sku: 'MA-007', name: 'ریمل حجم‌دهنده', category: 'آرایش', price: 260, stock: 70, emoji: '✨', bg: '#efe6fb',
    brief: 'حجم و بلندی، ضدآب',
    description: 'ریمل با برس انحنادار برای حجم و جداسازی مژه‌ها.',
    usage: 'از ریشه به نوک مژه بکشید و در صورت نیاز دو لایه بزنید.',
    ingredients: 'موم زنبور عسل، رنگدانه، پروتئین گندم' },
  { sku: 'PF-008', name: 'ادکلن زنانه', category: 'عطر', price: 1450, stock: 20, emoji: '🌸', bg: '#fde8ee',
    brief: 'رایحه گل و میوه، ماندگاری بالا',
    description: 'عطر با نت‌های گل یاس و میوه‌های استوایی.',
    usage: 'روی نبض مچ و پشت گردن از فاصله ۲۰ سانتی‌متر اسپری کنید.',
    ingredients: 'الکل، اسانس، آب' },
];

(async () => {
  for (const [k, v] of Object.entries({ hold_days: '0', min_payout: '500', shipping_fee: '60', max_total_bps: '1500' }))
    await pool.query('INSERT INTO settings(key,value) VALUES ($1,$2) ON CONFLICT DO NOTHING', [k, v]);

  if (!(await pool.query('SELECT 1 FROM commission_rules WHERE product_id IS NULL')).rowCount)
    for (const [l, bps] of [[1, 500], [2, 300], [3, 200]])
      await pool.query('INSERT INTO commission_rules(level,rate_bps) VALUES ($1,$2)', [l, bps]);

  const mk = async (name: string, email: string, pass: string, code: string, o: { role?: string; sponsor?: number | null; aff?: boolean }) => {
    await pool.query(
      `INSERT INTO users(name,email,password_hash,role,referral_code,sponsor_id,is_affiliate)
       VALUES ($1,$2,$3,$4,$5,$6,$7) ON CONFLICT (email) DO NOTHING`,
      [name, email, await bcrypt.hash(pass, 10), o.role ?? 'customer', code, o.sponsor ?? null, o.aff ?? false]);
    return (await pool.query('SELECT id FROM users WHERE email=$1', [email])).rows[0].id as number;
  };
  await mk('مدیر سایت', ADMIN_EMAIL, ADMIN_PASS, 'ADMIN001', { role: 'admin' });
  const sara = await mk('سارا', 'sara@example.com', DEMO_PASS, 'SARA2410', { aff: true });
  const ali = await mk('علی', 'ali@example.com', DEMO_PASS, 'ALI12345', { aff: true, sponsor: sara });
  const naz = await mk('نازنین', 'nazanin@example.com', DEMO_PASS, 'NAZ12345', { aff: true, sponsor: ali });
  await mk('مشتری آزمایشی', 'buyer@example.com', DEMO_PASS, 'BUYER001', { sponsor: naz });

  mkdirSync(join(process.cwd(), 'uploads'), { recursive: true });
  for (const p of products) {
    await pool.query(
      `INSERT INTO products(sku,name,category,brief,description,usage_instructions,ingredients,price,stock)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT (sku) DO NOTHING`,
      [p.sku, p.name, p.category, p.brief, p.description, p.usage, p.ingredients, p.price, p.stock]);
    const id = (await pool.query('SELECT id FROM products WHERE sku=$1', [p.sku])).rows[0].id;
    if (!(await pool.query('SELECT 1 FROM product_images WHERE product_id=$1', [id])).rowCount) {
      const file = `seed-${p.sku}.svg`;
      writeFileSync(join(process.cwd(), 'uploads', file),
        `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600"><rect width="600" height="600" fill="${p.bg}"/>` +
        `<text x="300" y="360" font-size="220" text-anchor="middle">${p.emoji}</text></svg>`);
      await pool.query('INSERT INTO product_images(product_id,url) VALUES ($1,$2)', [id, '/uploads/' + file]);
    }
  }

  console.log(`✔ seed done
  ادمین : ${ADMIN_EMAIL} / ${ADMIN_PASS}
  همکاران آزمایشی (رمز ${DEMO_PASS}): sara@example.com ← ali@example.com ← nazanin@example.com ← buyer@example.com (خریدار)
  لینک سارا: /r/SARA2410`);
  await pool.end();
})().catch(e => { console.error(e); process.exit(1); });
__EOF_FILE__
mkdir -p "$(dirname "src/server.ts")"
cat > 'src/server.ts' <<'__EOF_FILE__'
import express, { NextFunction, Request, Response } from 'express';
import cookieParser from 'cookie-parser';
import path from 'path';
import { PORT, COOKIE_SECURE, REF_COOKIE_MS } from './config';
import { pool } from './db';
import { HttpError, wrap } from './http';
import { loadUser } from './middleware/auth';
import authRoutes from './modules/auth/auth.routes';
import { publicRoutes, UPLOAD_DIR } from './modules/catalog/catalog.routes';
import ordersRoutes from './modules/orders/orders.routes';
import affiliateRoutes from './modules/affiliate/affiliate.routes';
import adminRoutes from './modules/admin/admin.routes';

const app = express();
app.set('trust proxy', 1);
app.use(express.json({ limit: '1mb' }));
app.use(cookieParser());
app.use(loadUser);

app.use('/uploads', express.static(UPLOAD_DIR, { maxAge: '7d' }));
app.use(express.static(path.join(process.cwd(), 'public')));

// لینک ارجاع: /r/CODE یا /r/CODE?p=محصول  → کوکی ۳۰ روزه
app.get('/r/:code', wrap(async (req, res) => {
  const code = String(req.params.code).toUpperCase();
  const u = (await pool.query('SELECT id FROM users WHERE referral_code=$1 AND is_active', [code])).rows[0];
  if (u && req.user?.id !== u.id) {
    res.cookie('ref', code, { maxAge: REF_COOKIE_MS, httpOnly: true, sameSite: 'lax', secure: COOKIE_SECURE });
  }
  const p = Number(req.query.p);
  res.redirect(Number.isInteger(p) && p > 0 ? `/#/product/${p}` : '/');
}));

app.use('/api/auth', authRoutes);
app.use('/api/affiliate', affiliateRoutes);
app.use('/api/orders', ordersRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api', publicRoutes);

app.use('/api', (_req, _res, next) => next(new HttpError(404, 'پیدا نشد')));
app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
  if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
  if (err?.name === 'MulterError') return res.status(400).json({ error: 'خطا در آپلود: ' + err.message });
  console.error(err);
  res.status(500).json({ error: 'خطای داخلی سرور' });
});

if (require.main === module) {
  app.listen(PORT, () => console.log(`✔ http://localhost:${PORT}`));
}
export default app;
__EOF_FILE__
mkdir -p "$(dirname "tests/commission.test.ts")"
cat > 'tests/commission.test.ts' <<'__EOF_FILE__'
import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import { pool, withTx, Tx } from '../src/db';
import { onOrderPaid, onDelivered, approveDue, onRefund } from '../src/modules/commission/commission.service';

class Rollback extends Error {}
// هر تست داخل یک تراکنش اجرا و در پایان برگردانده می‌شود تا دیتابیس تمیز بماند
const inTx = async (fn: (tx: Tx) => Promise<void>) => {
  try { await withTx(async tx => { await fn(tx); throw new Rollback(); }); }
  catch (e) { if (!(e instanceof Rollback)) throw e; }
};

let seq = 0;
const user = async (tx: Tx, sponsor: number | null, aff = true) =>
  (await tx.query(
    `INSERT INTO users(email,referral_code,sponsor_id,is_affiliate) VALUES ($1,$2,$3,$4) RETURNING id`,
    [`t${Date.now()}${seq}@t.dev`, `T${Date.now()}${seq++}`, sponsor, aff])).rows[0].id as number;

async function setup(tx: Tx, net = 1000, status = 'paid') {
  await tx.query('UPDATE commission_rules SET valid_to=now() WHERE product_id IS NULL AND valid_to IS NULL');
  for (const [l, b] of [[1, 500], [2, 300], [3, 200]]) await tx.query('INSERT INTO commission_rules(level,rate_bps) VALUES ($1,$2)', [l, b]);
  const a = await user(tx, null), b = await user(tx, a), c = await user(tx, b), d = await user(tx, c, false);
  const p = (await tx.query(`INSERT INTO products(sku,name,price) VALUES ($1,'x',$2) RETURNING id`, ['S' + Date.now() + seq++, net])).rows[0].id;
  const o = (await tx.query(
    `INSERT INTO orders(buyer_id,status,paid_at,total) VALUES ($1,$2,now(),$3) RETURNING id`, [d, status, net])).rows[0].id;
  const it = (await tx.query(
    `INSERT INTO order_items(order_id,product_id,qty,net_amount) VALUES ($1,$2,1,$3) RETURNING id`, [o, p, net])).rows[0].id;
  return { a, b, c, d, o, it };
}
const comm = async (tx: Tx, o: number) =>
  (await tx.query('SELECT beneficiary_id, level, amount, status FROM commissions WHERE order_id=$1 ORDER BY level', [o])).rows;

test('پورسانت سه‌سطحی: ۵٪ ۳٪ ۲٪ از مبلغ خالص', () => inTx(async tx => {
  const { a, b, c, o } = await setup(tx);
  await onOrderPaid(o, tx);
  const rows = await comm(tx, o);
  assert.deepEqual(rows.map(r => [r.beneficiary_id, r.level, r.amount]), [[c, 1, 50], [b, 2, 30], [a, 3, 20]]);
}));

test('ایدمپوتنسی: تکرار رویداد پورسانت اضافه نمی‌سازد', () => inTx(async tx => {
  const { o } = await setup(tx);
  await onOrderPaid(o, tx); await onOrderPaid(o, tx);
  assert.equal((await comm(tx, o)).length, 3);
}));

test('سفارش pending (پرداخت‌نشده) پورسانت ندارد', () => inTx(async tx => {
  const { o } = await setup(tx, 1000, 'pending');
  await onOrderPaid(o, tx);
  assert.equal((await comm(tx, o)).length, 0);
}));

test('همکار تعلیق‌شده یا غیرهمکار پورسانت نمی‌گیرد', () => inTx(async tx => {
  const { b, o } = await setup(tx);
  await tx.query('UPDATE users SET is_active=false WHERE id=$1', [b]);
  await onOrderPaid(o, tx);
  assert.deepEqual((await comm(tx, o)).map(r => r.level), [1, 3]);
}));

test('تا قبل از تحویل تأیید نمی‌شود؛ بعد از تحویل و پایان مهلت، به کیف پول می‌رود', () => inTx(async tx => {
  await tx.query(`INSERT INTO settings(key,value) VALUES ('hold_days','0') ON CONFLICT (key) DO UPDATE SET value='0'`);
  const { c, o } = await setup(tx);
  await onOrderPaid(o, tx);
  assert.equal(await approveDue(tx), 0);           // هنوز تحویل نشده
  await tx.query(`UPDATE orders SET status='delivered', delivered_at=now() WHERE id=$1`, [o]);
  await onDelivered(o, tx);
  assert.equal(await approveDue(tx), 3);
  const w = await tx.query(`SELECT COALESCE(SUM(amount),0) AS s FROM wallet_entries WHERE user_id=$1`, [c]);
  assert.equal(w.rows[0].s, 50);
}));

test('مرجوعی: پورسانت pending کم می‌شود و پورسانت تأییدشده از کیف پول کسر می‌شود', () => inTx(async tx => {
  await tx.query(`INSERT INTO settings(key,value) VALUES ('hold_days','0') ON CONFLICT (key) DO UPDATE SET value='0'`);
  const { c, o, it } = await setup(tx);
  await onOrderPaid(o, tx);
  await onRefund(it, 500, tx);                      // نصف مبلغ، قبل از تأیید
  assert.deepEqual((await comm(tx, o)).map(r => r.amount), [25, 15, 10]);

  await tx.query(`UPDATE orders SET status='delivered', delivered_at=now() WHERE id=$1`, [o]);
  await onDelivered(o, tx); await approveDue(tx);
  await onRefund(it, 500, tx);                      // نصف دوم، بعد از تأیید
  const w = await tx.query(`SELECT COALESCE(SUM(amount),0) AS s FROM wallet_entries WHERE user_id=$1`, [c]);
  assert.equal(w.rows[0].s, 0);
  assert.ok((await comm(tx, o)).every(r => r.status === 'reversed'));
}));

test('معرف بعد از تعیین تغییر نمی‌کند', () => inTx(async tx => {
  const a = await user(tx, null), b = await user(tx, null), c = await user(tx, a);
  await assert.rejects(() => tx.query('UPDATE users SET sponsor_id=$2 WHERE id=$1', [c, b]), /immutable/);
}));

after(() => pool.end());
__EOF_FILE__
mkdir -p "$(dirname "tsconfig.json")"
cat > 'tsconfig.json' <<'__EOF_FILE__'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "noEmit": true
  },
  "include": ["src", "tests"]
}
__EOF_FILE__
mkdir -p "$(dirname "uploads/.gitkeep")"
cat > 'uploads/.gitkeep' <<'__EOF_FILE__'

__EOF_FILE__
cp -n .env.example .env || true
echo; echo "✔ پروژه در پوشه $APP ساخته شد. مراحل بعد:"
echo "  cd $APP && npm install && npm run db:up && npm run migrate && npm run seed && npm run dev"
