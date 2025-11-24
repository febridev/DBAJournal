1. Ringkasan Masalah (Problem Summary)
Sistem monitoring Data Guard Broker (DGMGRL) menunjukkan status ERROR pada database standby nt19c2_std. Pemeriksaan detail (show database nt19c2_std) menampilkan dua error utama:

ORA-16766: Redo Apply is stopped

ORA-16853: apply lag has exceeded specified threshold

Ini mengindikasikan bahwa proses sinkronisasi data dari Primary ke Standby telah berhenti total, menyebabkan Standby tertinggal jauh.

2. Analisis Akar Masalah (Root Cause Analysis)
Akar masalah utamanya adalah penambahan sebuah datafile baru di salah satu Pluggable Database (PDB) di server Primary.

Meskipun database standby telah dikonfigurasi dengan STANDBY_FILE_MANAGEMENT=AUTO, proses pembuatan datafile otomatis di standby gagal. Kegagalan ini kemungkinan besar disebabkan oleh konfigurasi parameter DB_FILE_NAME_CONVERT yang tidak lengkap atau tidak sesuai untuk menerjemahkan path ASM dari Primary ke Standby.

Akibatnya, proses Redo Apply (MRP) di standby berhenti saat mencoba menerapkan perubahan tersebut, karena tidak dapat menemukan datafile fisik yang dibutuhkan.

3. Kronologi Error dan Solusi
Proses perbaikan melibatkan penyelesaian serangkaian error yang saling berkaitan, terutama karena lingkungan menggunakan arsitektur Multitenant (CDB/PDB).

Error 1: ORA-16766: Redo Apply is stopped
Why (Penyebab): Ini adalah gejala awal. Proses MRP (Managed Recovery Process) di standby berhenti. Ini bukan akar masalah, melainkan akibat dari masalah lain.

Solution (Solusi): Investigasi lebih lanjut dengan memeriksa alert log di server standby untuk menemukan penyebab sebenarnya MRP berhenti.

Error 2: ORA-01111, ORA-01110 (File UNNAMED00013)
Why (Penyebab): Alert log menunjukkan bahwa MRP berhenti karena tidak dapat menemukan datafile #13. Control file standby menandai file ini sebagai UNNAMED00013 karena tidak tahu di mana harus membuat file fisiknya.

Solution (Solusi): Melakukan perbaikan manual dengan mendaftarkan lokasi datafile yang benar menggunakan perintah ALTER DATABASE CREATE DATAFILE....

Error 3: ORA-01516: nonexistent ... file
Why (Penyebab): Perintah ALTER DATABASE CREATE DATAFILE dijalankan di container yang salah (CDB$ROOT). Datafile tersebut milik sebuah PDB, sehingga perintah harus dijalankan dari dalam PDB tersebut.

Solution (Solusi):

Mengidentifikasi nama PDB yang benar di server Primary.

Menghubungkan ke server Standby dan berpindah session ke dalam PDB yang benar menggunakan ALTER SESSION SET CONTAINER = <nama_pdb>;.

Error 4: ORA-01276: Cannot add file ... File has an Oracle Managed Files (OMF) name
Why (Penyebab): Klausa AS dalam perintah CREATE DATAFILE tidak menerima nama file dengan format OMF secara eksplisit. Oracle mengharuskan kita untuk hanya menunjuk lokasinya (disk group).

Solution (Solusi): Mengubah perintah menjadi ... AS '+DATA';, hanya dengan menyebutkan nama ASM disk group tujuan, membiarkan Oracle membuat nama filenya sendiri.

Error 5: ORA-01275: Operation CREATE DATAFILE is not allowed if standby file management is automatic
Why (Penyebab): Parameter STANDBY_FILE_MANAGEMENT disetel ke AUTO, yang merupakan mode proteksi untuk mencegah DBA melakukan perubahan file manual.

Solution (Solusi): Menonaktifkan proteksi ini untuk sementara dengan ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=MANUAL;.

Error 6: ORA-65040: operation not allowed from within a pluggable database
Why (Penyebab): Parameter STANDBY_FILE_MANAGEMENT adalah parameter tingkat CDB-wide (instance), sehingga tidak dapat diubah dari dalam sebuah PDB.

Solution (Solusi): Menyusun ulang urutan perintah dengan benar:

Hubungkan ke CDB$ROOT.

Jalankan ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=MANUAL;.

Pindah ke PDB (ALTER SESSION SET CONTAINER = <nama_pdb>;).

Jalankan ALTER DATABASE CREATE DATAFILE ... AS '+DATA';.

Kembali ke CDB$ROOT.

Jalankan ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO;.

Mulai ulang proses apply dari DGMGRL.

4. Langkah-langkah Pencegahan (Preventive Measures)
Untuk mencegah insiden ini terjadi lagi di masa depan:

Pertahankan STANDBY_FILE_MANAGEMENT=AUTO: Ini adalah praktik terbaik.

Konfigurasi DB_FILE_NAME_CONVERT dengan Benar: Pastikan parameter ini diatur dengan benar di spfile standby untuk menerjemahkan semua kemungkinan path, termasuk path ASM.

Contoh untuk kasus ini:

DB_FILE_NAME_CONVERT='+DATA/NT19C2_PRI/','+DATA/NT19C2_STD/'
(Sesuaikan +DATA dan nama unik database jika berbeda).

Verifikasi Konfigurasi: Setiap kali ada perubahan topologi storage, lakukan uji coba penambahan datafile di lingkungan development untuk memastikan konfigurasi Data Guard berjalan sesuai harapan.