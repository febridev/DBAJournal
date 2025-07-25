# Streaming Replica
- wal_level

<p> Fungsi: Parameter ini mengontrol jumlah informasi yang ditulis ke Write-Ahead Log (WAL). WAL adalah catatan perubahan data yang digunakan PostgreSQL untuk pemulihan dan replikasi.

Nilai yang Diperlukan: Untuk streaming replication, nilai wal_level harus diatur minimal ke replica.

minimal: Hanya mencatat informasi yang cukup untuk pemulihan crash. Tidak memadai untuk replikasi.

replica (atau hot_standby untuk versi lama, misal PostgreSQL 9.x): Menambahkan semua informasi yang diperlukan untuk menjalankan standby server dan mengarsipkan WAL. Ini adalah pengaturan minimum yang diperlukan agar streaming replication berfungsi.

logical: Menambahkan informasi yang diperlukan untuk logical decoding (digunakan untuk logical replication atau alat eksternal seperti Debezium). Jika Anda tidak menggunakan logical replication, replica sudah cukup.

Dampak: Semakin tinggi wal_level, semakin besar ukuran file WAL dan ada sedikit overhead penulisan, namun ini esensial untuk kemampuan replikasi dan pemulihan data yang robust.

Membutuhkan: Restart server agar perubahan berlaku.
</p>

- listen_addresses 

<p>Fungsi: Parameter ini menentukan alamat IP mana yang akan didengarkan oleh server PostgreSQL untuk koneksi masuk. Ini memastikan primary node dapat menerima koneksi dari standby node.

Nilai yang Diperlukan: Agar standby server dapat terhubung ke primary, primary harus mendengarkan koneksi dari standby.

localhost: Hanya menerima koneksi dari mesin lokal. Tidak akan memungkinkan standby dari mesin lain untuk terhubung.

*: Mendengarkan di semua alamat IP yang tersedia di primary node. Ini adalah pengaturan paling fleksibel agar primary bisa menerima koneksi dari standby di jaringan yang berbeda.

'IP_ADDRESS': Anda juga bisa menentukan alamat IP spesifik primary node tempat Anda ingin menerima koneksi.

Dampak: Jika listen_addresses tidak diatur dengan benar, standby tidak akan bisa membuat koneksi ke primary, sehingga replikasi tidak akan pernah dimulai.

Membutuhkan: Restart server agar perubahan berlaku.
</p>

- hot_standby 

<p>Fungsi: Parameter ini mengaktifkan kemampuan kueri hanya-baca (read-only queries) pada standby server saat sedang dalam mode pemulihan (yaitu, saat sedang menerima dan menerapkan WAL dari primary).

Nilai yang Diperlukan: Setel ke on.

on: Mengizinkan standby server untuk menerima koneksi baca-saja dari aplikasi Anda saat WAL sedang diterapkan. Ini sangat berguna untuk load balancing kueri baca atau sebagai node yang dapat langsung diakses setelah failover.

off: Standby server hanya akan berfungsi sebagai cold standby atau warm standby dan tidak dapat diakses untuk kueri sampai dipromosikan menjadi primary.

Dampak: Tanpa hot_standby = on, Anda tidak dapat menjalankan kueri SQL pada standby node saat sedang berfungsi sebagai replika, membatasi kegunaannya untuk reporting atau failover yang lebih cepat.

Membutuhkan: Restart server agar perubahan berlaku.

Gambaran Umum Alur Replikasi dengan Parameter Ini:

wal_level memastikan primary mencatat semua perubahan yang diperlukan ke dalam WAL.

listen_addresses memastikan primary "terbuka" dan "mendengar" koneksi replikasi yang datang dari standby.

hot_standby memastikan standby Anda tidak hanya menerima data, tetapi juga bisa diakses untuk kueri baca saat proses replikasi berlangsung.

Selain ketiga parameter ini, ingatlah bahwa Anda juga perlu mengkonfigurasi file pg_hba.conf di primary untuk mengizinkan koneksi replikasi dari standby, dan mengatur parameter primary_conninfo di postgresql.conf standby untuk memberitahu standby cara terhubung ke primary.
</p>