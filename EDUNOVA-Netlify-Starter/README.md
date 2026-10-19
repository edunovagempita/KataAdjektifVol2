# EDUNOVA — Projek asas Netlify + Supabase

Aplikasi React/Vite dalam bahasa Melayu, dengan UI responsif, log masuk/daftar Supabase, tiga dunia pembelajaran, nota, kuiz demonstrasi, ganjaran sesi, paparan pencapaian dan analisis contoh.

## 1. Jalankan secara setempat

```bash
npm install
cp .env.example .env
npm run dev
```

Isi `.env` dengan URL projek Supabase dan **anon/publishable key**. Jangan letak `service_role` dalam pemboleh ubah `VITE_*`.

## 2. Sediakan Supabase

1. Cipta projek Supabase.
2. Buka SQL Editor dan jalankan `supabase/schema.sql`.
3. Dalam Authentication → URL Configuration, tetapkan Site URL kepada URL Netlify dan tambah URL localhost untuk pembangunan.
4. Isi `VITE_SUPABASE_URL` dan `VITE_SUPABASE_ANON_KEY` dalam `.env` atau Environment variables Netlify.
5. Deploy projek ke Netlify.

## 3. Environment variables Netlify

- `VITE_SUPABASE_URL`: URL projek Supabase.
- `VITE_SUPABASE_ANON_KEY`: anon/publishable key untuk frontend.
- `SUPABASE_URL`: URL projek untuk Netlify Functions.
- `SUPABASE_ANON_KEY`: anon/publishable key untuk mengesahkan token dalam function admin.
- `SUPABASE_SERVICE_ROLE_KEY`: kunci rahsia pelayan sahaja. Jangan guna awalan `VITE_`, jangan commit ke Git dan jangan hantar kepada browser.

`SUPABASE_DATABASE_URL` bukan URL yang patut digunakan sebagai URL Supabase JS client. Gunakan URL projek `https://....supabase.co`. Netlify extension boleh menamakan pemboleh ubah mengikut framework; semak nilai sebenar dan petakan ke nama di atas.

## 4. Peranan pengguna

Pendaftaran awam mencipta akaun sebagai `murid` sahaja melalui trigger pangkalan data. Jangan percaya peranan yang dihantar dari browser. Tetapkan peranan guru/ibu bapa/admin melalui prosedur pentadbiran yang disahkan. Jangan beri hak admin kepada pengguna awam.

## 5. Kandungan nota dan soalan

Antaramuka sekarang mengandungi nota dan soalan demonstrasi berdasarkan topik dalam fail bank: kata adjektif perasaan, cara, pancaindera, bentuk, jarak, waktu, warna, ukuran dan sifatan/keadaan. Untuk produksi, import semua bank nota/soalan ke `learning_content` dan tukar kuiz demo supaya membaca kandungan itu dari Supabase. Jangan hantar skema jawapan kepada client untuk penilaian rasmi; gunakan Netlify Function atau RPC berizin untuk menyemak jawapan dan merekod markah.

## 6. Perkara yang masih perlu disambungkan

- Import keseluruhan bank soalan dan nota ke Supabase.
- Fungsi pelayan untuk markah, coins, XP, streak, trofi dan nyahkunci zon supaya pengguna tidak boleh mengubah ganjaran sendiri.
- Hubungan guru-kelas-murid dan kod pautan ibu bapa yang tamat tempoh.
- Analisis kelas sebenar dan pengiraan TP 1–6 berdasarkan rubrik yang ditetapkan guru. Skor kuiz sahaja tidak semestinya sama dengan TP.
- Penyedia AI melalui fungsi pelayan; jangan letak API key AI dalam frontend. AI mesti mengambil konteks daripada bank kandungan, tidak mereka jawapan dan dinyahaktifkan semasa ujian rasmi.
- Integrasi PRPM DBP memerlukan semakan API/lesen/ketersediaan. Ia belum dipanggil oleh projek asas ini.
- Pengurusan pengguna, reset kata laluan, audit log dan fungsi admin penuh.

## 7. Keselamatan penting

SQL menggunakan RLS dan jadual peranan asas. Uji polisi dengan akaun murid, guru, ibu bapa dan admin berasingan sebelum data sebenar dimasukkan. Data kanak-kanak memerlukan kebenaran, kawalan akses, dasar penyimpanan dan pemadaman yang jelas. Jangan paparkan kedudukan kelas peribadi kepada murid lain secara automatik.
