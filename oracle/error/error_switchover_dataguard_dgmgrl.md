🧐 Why (Akar Masalah)
Kegagalan switchover terjadi karena proses DGMGRL terputus saat mencoba mengubah peran database primary lama menjadi standby baru.

Proses Switchover: Saat switchover, primary lama harus dimatikan (shutdown) dan dihidupkan kembali dalam mode mount.

Ketergantungan DGMGRL: Untuk melakukan ini secara otomatis, DGMGRL dari server primary baru perlu terhubung kembali ke listener di server primary lama.

Titik Kegagalan: Ketika instance database primary lama dalam keadaan shutdown atau mount, ia tidak mendaftarkan layanannya secara dinamis ke listener.

Hasil: Listener di server primary lama tidak mengenali SERVICE_NAME khusus (..._DGMGRL) yang diminta oleh DGMGRL, sehingga koneksi ditolak dengan error ORA-12545 (target host or object does not exist). Intinya, DGMGRL kehilangan "pegangan" untuk mengelola instance tersebut.

🛠️ Solution (Solusi)
Solusinya adalah dengan memberikan "peta" atau jalur koneksi permanen ke listener agar DGMGRL selalu bisa terhubung, terlepas dari status database. Ini disebut registrasi listener statis.

1. Perbaikan Jangka Panjang (Pencegahan)
Lakukan konfigurasi ini di file listener.ora pada SEMUA server database (baik primary maupun standby) untuk memastikan switchover dan failover berjalan lancar ke arah mana pun.

Tindakan: Edit file $ORACLE_HOME/network/admin/listener.ora. Tambahkan blok SID_DESC untuk layanan DGMGRL di dalam SID_LIST_LISTENER.

Contoh Template listener.ora yang Benar:

Code snippet

# Pastikan hanya ada SATU SID_LIST_LISTENER
SID_LIST_LISTENER =
  (SID_LIST =
    # Blok untuk Data Guard Broker
    (SID_DESC =
      (GLOBAL_DBNAME = <db_unique_name>_DGMGRL.<domain>) # Contoh: ntl19c2_pri_DGMGRL.localdomain
      (ORACLE_HOME = <path_ke_oracle_home_anda>)      # Contoh: /u01/app/oracle/product/19.0.0/dbhome_1
      (SID_NAME = <nama_sid_database_anda>)           # Contoh: ntl19c2
    )

    # Anda bisa menambahkan SID_DESC lain di sini jika perlu
    # (SID_DESC = ... )
  )
Aktivasi: Setelah menyimpan file, jalankan perintah berikut agar listener membaca konfigurasi baru tanpa perlu restart.

Bash

lsnrctl reload
2. Penanganan Jangka Pendek (Jika Sudah Terjadi)
Jika switchover sudah terlanjur gagal, selesaikan secara manual seperti yang diinstruksikan oleh DGMGRL.

Login ke server primary lama.

Masuk ke SQL*Plus: sqlplus / as sysdba.

Jalankan: STARTUP MOUNT;.

Kembali ke DGMGRL dan aktifkan lagi database tersebut: ENABLE DATABASE '<nama_db_primary_lama>';.

✨ Key Takeaway (Poin Kunci)
Data Guard Broker (DGMGRL) memerlukan koneksi statis ke database yang dikelolanya. Ini untuk menjamin DGMGRL tetap bisa berkomunikasi dan memberi perintah (shutdown, startup mount) bahkan ketika database tidak berjalan dalam mode OPEN penuh. Tanpa registrasi statis, otomatisasi DGMGRL akan gagal saat role transition.