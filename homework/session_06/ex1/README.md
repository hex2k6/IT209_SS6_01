# Bài 1: Khảo sát FHS và phân quyền File/Folder nâng cao

## Môi trường thực hành

Bài được thực hiện trên Ubuntu của GitHub Actions bằng tài khoản non-root `runner`, sử dụng `sudo` khi cần quyền quản trị. Nhóm sở hữu là `www-data`. Script đầy đủ: [practice.sh](practice.sh). Môi trường Windows cục bộ chưa cài bản phân phối WSL nên không dùng kết quả phân quyền giả lập trên Windows.

## Khảo sát FHS

| Đường dẫn | Vai trò |
| --- | --- |
| `/` | Gốc của cây thư mục Linux |
| `/etc` | Cấu hình hệ thống |
| `/usr` | Chương trình, thư viện và tài nguyên dùng chung |
| `/var` | Dữ liệu thay đổi trong quá trình vận hành |
| `/var/log` | Vị trí thông thường của nhật ký hệ thống |
| `/home` | Thư mục cá nhân của người dùng thông thường |
| `/tmp` | Dữ liệu tạm |

`/var/www` là vị trí triển khai web phổ biến, được dùng theo đề bài. Nhật ký của ứng dụng trong bài đặt tại `/var/www/my-app/logs`; đây là cách tổ chức của bài tập, không phải vị trí bắt buộc cho mọi nhật ký theo FHS.

Cấu trúc đã tạo:

```text
/var/www/my-app/
├── public/
│   └── index.html
└── logs/
    └── app.log
```

## Nhật ký lệnh thực hiện

Script chạy từ tài khoản non-root. Biến `owner` lấy tên tài khoản hiện tại, tương đương `$USER` trong phiên đăng nhập thông thường.

```bash
owner=$(id -un)
id
pwd
ls -ld / /etc /usr /var /tmp /home
getent group www-data

sudo mkdir -p /var/www/my-app/public /var/www/my-app/logs
printf '<!doctype html><html lang="vi"><meta charset="utf-8"><title>My App</title><h1>My App</h1></html>\n' | sudo tee /var/www/my-app/public/index.html >/dev/null
printf 'Application initialized.\n' | sudo tee /var/www/my-app/logs/app.log >/dev/null

sudo chown -R "$owner":www-data /var/www/my-app
sudo chmod 750 /var/www/my-app
sudo chmod 750 /var/www/my-app/public
sudo chmod 770 /var/www/my-app/logs

# Áp dụng lại cùng quyền bằng ký tự để thực hành symbolic.
sudo chmod u=rwx,g=rx,o= /var/www/my-app/public
sudo chmod u=rwx,g=rwx,o= /var/www/my-app/logs

# File thông thường không cần quyền thực thi.
sudo chmod 640 /var/www/my-app/public/index.html
sudo chmod 660 /var/www/my-app/logs/app.log

cd /var/www/my-app
pwd
cd public
pwd
cd ../logs
pwd
cd ..
ls -la /var/www/my-app
stat -c '%A %a %U:%G %n' public logs public/index.html logs/app.log
```

Ba lần `pwd` khi điều hướng lần lượt trả về `/var/www/my-app`, `/var/www/my-app/public` và `/var/www/my-app/logs`.

## Giải thích phân quyền và sở hữu

Mỗi bộ ba quyền dùng `r=4`, `w=2`, `x=1`, cộng lại để tạo chữ số octal. Thứ tự là Owner, Group, Others. Trên thư mục, `r` cho phép liệt kê tên, `w` cho phép thay đổi các mục bên trong khi có quyền truy cập phù hợp, còn `x` cho phép đi qua/truy cập thư mục.

| Đối tượng | Octal | Symbolic | Ý nghĩa |
| --- | --- | --- | --- |
| `my-app` | `750` | `rwxr-x---` | Owner toàn quyền, group đọc/truy cập, others không có quyền |
| `public` | `750` | `rwxr-x---` | Owner toàn quyền, group đọc/truy cập, others không có quyền |
| `logs` | `770` | `rwxrwx---` | Owner và group toàn quyền, others không có quyền |
| `public/index.html` | `640` | `rw-r-----` | Owner đọc/ghi, group đọc, others không có quyền |
| `logs/app.log` | `660` | `rw-rw----` | Owner và group đọc/ghi, others không có quyền |

`chown -R "$owner":www-data` đổi đồng thời chủ sở hữu và nhóm của thư mục cùng toàn bộ nội dung đã tạo. Owner là `runner`, không phải `root`. Nếu chỉ muốn đổi nhóm, có thể dùng `chgrp`; bài thực hành dùng `chown` để thực hiện cả hai yêu cầu.

**Làm rõ điểm không nhất quán trong đề:** mô tả public chỉ có đọc/ghi và đọc tương ứng `640`, nhưng thư mục cần `x` để truy cập. Vì vậy bài theo gợi ý và kết quả mong đợi `750`. Chuỗi `drwxrwxr--` thực tế là `774`, không phải `770`, và cấp quyền đọc cho Others. Bài dùng `drwxrwx---` (`770`) để đáp ứng ràng buộc Others không có quyền. Chữ `d` là loại thư mục, không nằm trong ba chữ số quyền.

Tên `public` chỉ vai trò nội dung web; không có nghĩa cấp quyền Linux cho mọi người dùng hệ thống. Việc truy cập HTTP còn phụ thuộc cấu hình web server; bài này chỉ kiểm tra quyền filesystem.

## Đầu ra thực tế và kiểm tra

Đã chạy thành công trên Ubuntu 24.04.5 LTS tại [GitHub Actions — run 37483812832](https://github.com/hex2k6/IT209_SS6_01/actions/runs/37483812832), commit thực hành `a7c1596`. Nhật ký lệnh và kết quả được trích trong [command-output.txt](command-output.txt); chỉ bỏ tiền tố timestamp do GitHub thêm vào từng dòng.

Đầu ra nguyên văn của `ls -la /var/www/my-app`:

```text
total 16
drwxr-x--- 4 runner www-data 4096 Oct  6 15:01 .
drwxr-xr-x 4 root   root     4096 Oct  6 15:01 ..
drwxrwx--- 2 runner www-data 4096 Oct  6 15:01 logs
drwxr-x--- 2 runner www-data 4096 Oct  6 15:01 public
```

Kiểm tra bổ sung bằng `stat`:

```text
drwxr-x--- 750 runner:www-data public
drwxrwx--- 770 runner:www-data logs
-rw-r----- 640 runner:www-data public/index.html
-rw-rw---- 660 runner:www-data logs/app.log
```

Các kiểm tra trong script đều thành công: owner có UID 1001 (khác 0); group `www-data` đọc được file static và truy cập `public` nhưng không ghi vào thư mục này; group đọc, ghi và truy cập được `logs`; tài khoản `nobody` không truy cập được hai thư mục. Kết quả cuối:

```text
PASS: directory modes, ownership, group access and others restrictions.
```

Thư mục được tạo trong máy Ubuntu tạm thời của lần chạy Actions; báo cáo và log là bằng chứng được lưu trong repository. Git không lưu quyền sở hữu và toàn bộ quyền octal của thư mục, nên cần chạy các lệnh Linux để tái tạo, không thể chỉ dựa vào clone repository.
