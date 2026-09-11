# SmartTrip Batam - Daftar Halaman untuk Mockup

Panduan buat tim UI/UX - isinya murni soal apa yang dilihat dan dilakukan user di tiap layar (input, tombol, konten). Tidak ada istilah teknis/backend, jadi bisa langsung dipakai buat bikin wireframe.

26 layar total: 19 buat user biasa, 7 buat admin (satu layar "pilih lokasi di peta" dipakai ulang di dua tempat, jadi cuma perlu didesain sekali).

---

## A. Onboarding & Masuk Akun

### A1. Splash / Pilihan Bahasa
**Tujuan:** Layar pertama saat buka app. User pilih bahasa sebelum masuk ke mana-mana.
**Konten:** Logo/nama app, tagline singkat.
**Tombol:** Bahasa Indonesia / English (dua pilihan besar).
**Lanjut ke:** Halaman Home.

### A2. Masuk (Login)
**Tujuan:** User yang sudah punya akun masuk ke app.
**Konten:** Logo app, judul "Masuk".
**Input:** Email, Password.
**Tombol:** "Masuk" (tombol utama), "Masuk pakai Google", "Belum punya akun? Daftar" (link ke halaman Daftar). Tidak ada opsi "lewati aja"/pakai app tanpa akun.
**Pesan error:** Email/password salah, gagal masuk pakai Google.

### A3. Daftar (Register)
**Tujuan:** Bikin akun baru.
**Input:** Nama, Email, Password, Konfirmasi Password.
**Tombol:** "Daftar" (tombol utama), "Daftar pakai Google", "Sudah punya akun? Masuk" (link balik ke halaman Masuk).

### A4. Pilih Minat (wajib diisi)
**Tujuan:** User pilih minimal satu minat wisata sebelum bisa lanjut pakai app - muncul tiap kali login/buka app selama user belum pernah isi ini sama sekali (bukan cuma sekali doang pas awal daftar).
**Konten:** Teks singkat ("Pilih minimal 1 kategori yang kamu suka").
**Input:** Kumpulan chip/tombol kategori yang bisa dipilih lebih dari satu (contoh: Alam, Kuliner Seafood, Belanja, Sejarah, dst).
**Tombol:** "Lanjut" (abu-abu/tidak aktif sampai minimal 1 kategori dipilih). Tidak ada tombol "lewati".
**Catatan:** User tidak bisa keluar dari layar ini sebelum pilih minimal 1 kategori.

---

## B. Jelajah & Cari Tempat

### B1. Home
**Tujuan:** Halaman utama, bisa dilihat siapa saja walau belum login.
**Konten:** Daftar kartu tempat wisata/kuliner/hotel (foto, nama, kategori, rating, kisaran harga), bisa di-scroll terus (makin di-scroll makin muncul tempat baru).
**Tombol:** Chip filter kategori di atas, kolom pencarian, tombol "+ tambah ke wishlist" di tiap kartu, tap kartu buat buka Detail Tempat. Menu bawah: Home / Trip Saya / Profil (+ tab Admin kalau user itu admin).
**Tombol utama:** "Buat Trip" (tombol menonjol) - kalau belum login, diarahkan ke halaman Masuk dulu.
**Kalau kosong:** "Belum ada data tempat, coba lagi nanti."

### B2. Detail Tempat
**Tujuan:** Info lengkap satu tempat wisata/kuliner/hotel.
**Konten:** Galeri foto (bisa digeser), nama tempat, tag kategori, alamat, nomor telepon, website, jam buka, rating, kisaran harga, deskripsi tempat (ada versi Indonesia & Inggris), link buka di Google Maps.
**Tombol:** "+ Wishlist" (kalau lagi dalam proses bikin trip), "Tulis Review", "Buka di Google Maps", tombol back.
**Konten tambahan:** Daftar review dari user lain (rating + komentar), rata-rata rating di bagian atas.
**Kalau kosong:** "Jadi yang pertama kasih review."

---

## C. Proses Bikin Trip

Cuma bisa diakses kalau sudah login.

### C1. Atur Trip
**Tujuan:** Langkah pertama - isi info dasar trip.
**Input:** Jumlah hari (angka, naik-turun), Total anggaran (isi angka rupiah), Tanggal mulai trip (pilih tanggal), Jam mulai & selesai jalan-jalan tiap hari (opsional, sudah ada default jam 9 pagi - 7 malam), tombol pilih Ya/Tidak "Sudah punya hotel?".
**Tombol:** "Lanjut" (tombol utama), tombol back (muncul konfirmasi kalau mau batal).
**Konten tambahan:** Indikator progress (langkah 1 dari beberapa langkah).

### C2. Susun Wishlist
**Tujuan:** Opsional - tambahkan tempat yang memang sudah pengen dikunjungi sebelum sistem bikin jadwal otomatis.
**Konten:** Daftar kartu tempat yang bisa di-scroll, sama seperti Home, tapi ada tombol "+ wishlist" di tiap kartu dan penghitung jumlah yang sudah ditambah ("3 tempat ditambahkan").
**Tombol:** "Tambah manual" (buka layar pilih lokasi di peta, buat tempat yang tidak ada di daftar), "Lanjut" (tetap bisa lanjut walau belum nambah apa-apa), "Lewati", tombol back.
**Konten tambahan:** Daftar tempat yang sudah ditambahkan ke wishlist, masing-masing ada tombol hapus (×).

### C2a. Pilih Lokasi di Peta (layar/pop-up)
**Tujuan:** Tambah tempat yang tidak ada di daftar app - dipakai ulang di dua tempat: nambah wishlist manual dan nambah hotel manual.
**Konten:** Peta, user tap/geser buat naruh titik lokasi, kolom isi nama tempat di bawah peta.
**Tombol:** "Simpan", "Batal".

### C3. Pilih Minat + Atur Prioritas
**Tujuan:** Dua hal di satu layar - minat khusus buat trip ini, dan seberapa penting masing-masing faktor buat sistem waktu kasih rekomendasi.
**Bagian 1 - Minat:** Chip kategori yang bisa dipilih lebih dari satu, sama kayak layar Pilih Minat awal - sudah keisi otomatis dari minat yang tersimpan di profil, tapi bisa diubah khusus buat trip ini.
**Bagian 2 - Prioritas:** 4 slider (geser dari 0 sampai 10) buat: Kesesuaian minat, Jarak/lokasi, Kesesuaian anggaran, Rating/popularitas tempat. Sudah keisi otomatis dari pengaturan di profil.
**Tombol:** Toggle "Simpan sebagai pilihan default" (mati secara default), "Lanjut", tombol back.

### C4. Pilih Hotel
**Tujuan:** Tentukan hotel jadi titik awal & akhir tiap hari perjalanan.
**Kalau user sudah punya hotel (dipilih di langkah C1):** Kolom pencarian hotel (ketik nama, muncul saran), tap buat pilih. Kalau tidak ketemu, ada tombol "Tidak ketemu?" buat buka layar pilih lokasi di peta.
**Kalau user belum punya hotel:** Sistem tampilkan 3 pilihan hotel rekomendasi (kartu berisi nama, foto, kisaran harga, rating, jarak dari area wisata), tinggal tap buat pilih.
**Tombol:** "Lanjut" (aktif setelah hotel terpilih), tombol back.

### C5. Sedang Membuat Itinerary (loading)
**Tujuan:** Layar tunggu selagi sistem menyusun jadwal perjalanan.
**Konten:** Animasi loading, teks status yang bisa berganti-ganti ("Menyusun rute...", "Menghitung tempat terbaik...") - ini bagian polish, opsional.
**Tombol:** Tidak ada, belum bisa dibatalkan di tahap ini.

---

## D. Hasil Itinerary & Kelola Trip

### D1. Hasil Itinerary
**Tujuan:** Layar utama menampilkan jadwal trip yang sudah jadi (baik baru dibuat atau dibuka lagi).
**Konten:** Judul & tanggal trip di atas, lalu tab atau daftar kartu per hari.
**Isi tiap kartu hari:** Nomor/tanggal hari, daftar tempat yang dikunjungi sesuai urutan, tiap tempat ada foto kecil, nama, label penanda ("Dari Wishlist" / "Rekomendasi"), perkiraan lama kunjungan. Kartu ramalan cuaca muncul kalau tanggal hari itu sudah dekat (sekitar seminggu lagi). Kalau jadwal hari itu terlalu padat, ada peringatan kecil di kartunya.
**Tombol per tempat:** Tap buat buka Detail Tempat, menu titik tiga → Ganti Tempat.
**Tombol per hari:** "Buka Peta" (buka Peta Live buat hari itu), lencana peringatan cuaca (cuma muncul kalau ada tempat outdoor + prediksi hujan - tap langsung buka layar Ganti Tempat).
**Tombol di layar:** "Edit Trip" (balik ke pengaturan awal, tapi kalau ubah jumlah hari/anggaran/hotel jadwal akan disusun ulang dari awal - ada konfirmasi dulu), "Hapus Trip" (ada konfirmasi), tombol back.

### D2. Ganti Tempat (pop-up)
**Tujuan:** Ganti satu tempat di jadwal tanpa mengubah tempat lain.
**Konten:** Dua tab - "Rekomendasi" (pilihan alternatif dari sistem, area/kategori mirip) dan "Cari Manual" (pencarian bebas semua tempat).
**Tombol:** Tap kartu tempat buat pilih jadi pengganti, "Batal".

### D3. Daftar Trip Tersimpan
**Tujuan:** Semua trip yang pernah dibuat user.
**Konten:** Daftar kartu trip (judul, rentang tanggal, jumlah hari, foto kecil).
**Tombol:** Tap kartu buat buka trip itu, "Buat Trip" (mulai bikin trip baru), swipe atau menu titik tiga per kartu buat "Hapus" (ada konfirmasi).
**Kalau kosong:** "Trip pertamamu tinggal 1 tap lagi" + tombol "Buat Trip" yang menonjol.

### D4. Detail Ramalan Cuaca (opsional)
**Tujuan:** Tap kartu cuaca di layar Hasil Itinerary bisa langsung nampilin info singkat, atau buka layar detail kecil ini - tergantung keputusan tim, dimasukin di sini biar lengkap.
**Konten:** Info cuaca lebih lengkap per hari (kisaran suhu, kemungkinan hujan, deskripsi singkat).
**Tombol:** Tutup.

### D5. Form Kasih Review
**Tujuan:** Kasih rating/review ke suatu tempat. Bisa diakses dari halaman Detail Tempat (review umum) atau habis selesai kunjungan di dalam trip.
**Input:** Rating bintang (1-5, wajib diisi), komentar (opsional, bisa panjang).
**Tombol:** "Kirim", "Batal".

---

## E. Selama Trip Berlangsung

### E1. Peta Live
**Tujuan:** Layar peta yang aktif nemenin user selama jalan-jalan di hari itu, mirip navigasi Google Maps - dibuka dari tombol "Buka Peta" di Hasil Itinerary.
**Konten:** Peta dengan penanda hotel/titik awal, penanda bernomor buat tiap tempat yang akan dikunjungi (semua langsung kelihatan dari awal), garis rute yang berubah warna abu-abu kalau sudah dikunjungi dan biru kalau belum, titik lokasi user yang bergerak live, indikator kecil "tracking aktif". Kartu ramalan cuaca juga muncul kalau tanggalnya sudah dekat.
**Tombol:** "Mulai Hari Ini" (tap pertama buat mulai tracking otomatis hari itu), tekan-tahan penanda tempat manapun buat tandai/batalkan sudah dikunjungi secara manual, tap penanda buat buka kartu info kecil dengan opsi "Ganti Tempat", tombol back.
**Catatan:** Kalau user tolak izin lokasi, peta tetap bisa dipakai, cuma penandaan "sudah dikunjungi"-nya jadi manual semua (tidak otomatis).

---

## F. Akun

### F1. Profil
**Tujuan:** Pengaturan akun, terpisah dari trip manapun.
**Konten:** Nama, email, cara login (password atau lewat Google).
**Input:** Chip minat + 4 slider prioritas, sama seperti di proses bikin trip, tapi ini buat pengaturan default.
**Tombol:** "Simpan", tombol ganti bahasa (ID/EN), "Keluar" (ada konfirmasi).

---

## G. Admin (tab tambahan, cuma muncul buat akun admin)

### G1. Dashboard Admin
**Tujuan:** Halaman ringkasan buat admin.
**Konten:** Kartu/grafik ringkasan - tempat paling banyak di-wishlist user, rata-rata rating dari user, jumlah trip yang dibuat, daftar tempat yang belum ada info harganya, daftar tempat yang tag kategorinya belum dicek admin, info kapan terakhir kali data tempat baru diambil dari Google.
**Tombol:** Pintasan ke halaman Review Tempat Baru, Daftar Semua Tempat, Daftar Kategori.
**Kalau kosong:** "Belum ada data, mulai dari cari tempat baru" + tombol langsung ke sana.

### G2. Review Tempat Baru
**Tujuan:** Admin cek & setujui tempat baru sebelum masuk ke daftar rekomendasi app.
**Tombol (atas):** "Cari Tempat Baru" (sistem cari tempat baru dari Google, muncul notifikasi kalau sudah selesai).
**Konten:** Daftar tempat kandidat yang bisa difilter berdasarkan area dan status (belum dicek/disetujui/ditolak). Tiap baris nampilin nama, tipe kira-kira, area.
**Tombol per baris:** "Setujui" (tempat lengkap otomatis - foto, deskripsi, kategori - baru masuk ke daftar utama), "Tolak" (tempat ini tidak akan dimunculkan lagi ke daftar review berikutnya).
**Aksi banyak sekaligus:** Bisa centang beberapa lalu Setujui/Tolak sekaligus.

### G3. Daftar Semua Tempat (Admin)
**Tujuan:** Cari/lihat semua tempat yang sudah ada di app, titik masuk buat edit.
**Konten:** Daftar tempat yang bisa dicari & difilter.
**Tombol:** Tap baris buat edit, "+ Tambah Manual" (buat nambah tempat yang tidak ada di Google).

### G4. Form Edit Tempat (Admin)
**Tujuan:** Admin lengkapi/perbaiki info satu tempat.
**Input:** Estimasi biaya, perkiraan lama kunjungan, apakah tempat ini outdoor (ya/tidak), tag kategori (bisa pilih beberapa), deskripsi versi Indonesia, deskripsi versi Inggris.
**Konten tambahan:** Info dasar dari Google ditampilkan buat referensi (nama, rating, alamat, dst) tapi tidak bisa diedit.
**Tombol:** "Simpan", "Hapus" (cuma buat tempat yang ditambah manual), tombol back.

### G5. Daftar Kategori (Admin)
**Tujuan:** Kelola daftar kategori/tag minat yang dipakai di seluruh app.
**Konten:** Daftar kategori (nama Indonesia, nama Inggris).
**Tombol:** "+ Tambah Kategori", tap baris buat edit, ikon hapus per baris (ada konfirmasi, peringatan kalau kategori masih dipakai).

### G6. Form Edit Kategori (Admin)
**Input:** Nama Indonesia, Nama Inggris.
**Tombol:** "Simpan", "Batal".

### G7. Status Sinkronisasi Data (Admin)
**Tujuan:** Admin pantau kapan terakhir data tempat baru diambil dan seberapa banyak kuota yang sudah dipakai.
**Konten:** Waktu pencarian tempat baru terakhir kali dijalankan, hasil ringkas (berapa disetujui, berapa gagal), indikator pemakaian kuota bulanan.
**Tombol:** Link balik ke halaman Review Tempat Baru.

---

## Tabel Ringkasan

| # | Layar | Bagian |
|---|--------|---------|
| A1 | Splash / Bahasa | Onboarding |
| A2 | Masuk | Onboarding |
| A3 | Daftar | Onboarding |
| A4 | Pilih Minat (wajib) | Onboarding |
| B1 | Home | Jelajah |
| B2 | Detail Tempat | Jelajah |
| C1 | Atur Trip | Bikin Trip |
| C2 | Susun Wishlist | Bikin Trip |
| C2a | Pilih Lokasi di Peta | Bikin Trip (dipakai ulang) |
| C3 | Pilih Minat + Prioritas | Bikin Trip |
| C4 | Pilih Hotel | Bikin Trip |
| C5 | Sedang Membuat (loading) | Bikin Trip |
| D1 | Hasil Itinerary | Kelola Trip |
| D2 | Ganti Tempat | Kelola Trip |
| D3 | Daftar Trip Tersimpan | Kelola Trip |
| D4 | Detail Cuaca (opsional) | Kelola Trip |
| D5 | Form Kasih Review | Kelola Trip |
| E1 | Peta Live | Selama Trip |
| F1 | Profil | Akun |
| G1 | Dashboard Admin | Admin |
| G2 | Review Tempat Baru | Admin |
| G3 | Daftar Semua Tempat | Admin |
| G4 | Form Edit Tempat | Admin |
| G5 | Daftar Kategori | Admin |
| G6 | Form Edit Kategori | Admin |
| G7 | Status Sinkronisasi | Admin |

**19 layar user biasa (A1-F1) + 7 layar admin (G1-G7) = 26 layar berbeda.** Layar "Pilih Lokasi di Peta" (C2a) cukup didesain sekali, dipakai ulang di dua alur berbeda. Layar Detail Cuaca (D4) opsional - kalau waktu terbatas, isinya bisa cukup jadi tooltip kecil di layar Hasil Itinerary saja.
</content>
