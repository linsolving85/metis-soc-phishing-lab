# metis-soc-phishing-lab

METIS「Linux 主機」關卡：SOC 釣魚郵件分析 + 網域封鎖（初學者友善版，約 10 分鐘）。
學生看信件標頭、解開網頁裡用 base64 藏起來的收帳密網址，最後用 `/etc/hosts` 把它導到 sinkhole。

Flag 格式統一為 `metis{<base64>}`，例如 `metis{bWV0aXMK}`。
情境中的網域都用保留的 `.example`、IP 都用 RFC 5737 範圍，不指向任何真實公司。

## 映像
`ghcr.io/linsolving85/metis-soc-phishing-lab:v1.0.0`

推 `v*` tag 時由 GitHub Actions（`.github/workflows/build-image.yml`）建置並推到 ghcr，job summary 會印出含 `@sha256:` 的完整名稱。完成後把套件可見度設成 Public。

## 在關卡編輯器怎麼填

| 欄位 | 填什麼 |
|---|---|
| 標題 | SOC 事件應變：釣魚郵件分析與網域封鎖 |
| 難度／預估時間 | 簡單／10m |
| 標籤 | `linux, soc, phishing, base64` |
| 目標 → 類型 | Linux 主機 |
| 映像 | `ghcr.io/linsolving85/metis-soc-phishing-lab:v1.0.0` |
| 登入使用者／shell | student／/bin/bash |
| 允許 sudo／SUID 提權 | **要勾**（第 3 題要用 sudo 寫 /etc/hosts 與執行驗證腳本） |
| 提供攻擊機終端機 | 不勾 |

### 第 1 題：看穿偽造的寄件人（配分 30）
- 題目說明：到業務部同事的電腦打開終端機，先 `cat notes.txt`。信箱在 `/var/mail/student`，3 封信裡有一封寄件人被偽造成公司 IT，從它的標頭找出答案。
- 答案：`metis{aGVhZGVyX3NwZl9mYWls}`（不要勾「忽略大小寫」）
- 提示 1（扣 0.1）：`From` 可以隨便寫，`Return-Path`、`Received` 與 `Authentication-Results`（spf／dmarc）才看得出真正的寄件來源。
- 提示 2（扣 0.3）：`grep -n -iE '^(subject|from|return-path|x-)|spf=' /var/mail/student`，找 spf=fail 那封信的 `X-` 標頭。

### 第 2 題：解開被藏起來的收帳密網址（配分 30）
- 題目說明：沙箱把信中連結存成 `~/evidence/login.html`。表單上寫的目的地看起來是 Microsoft，但同事的帳密其實被送到別處。找出真正的目的地，答案就在那個網址裡。
- 答案：`metis{ZGVjb2RlZF9waGlzaF9ob3N0}`（不要勾「忽略大小寫」）
- 提示 1（扣 0.1）：HTML 寫的 `action` 可以在送出那一刻被 JavaScript 換掉；釣魚工具常用 `atob()`（base64）把網址藏起來。
- 提示 2（扣 0.3）：`grep -n -A3 'atob\|_cfg' ~/evidence/login.html`，把引號裡的字串用 `echo '<字串>' | base64 -d` 解開。

### 第 3 題：封鎖收帳密的主機（配分 40）
- 題目說明：到機房的 DNS 主控台，用 `/etc/hosts` 把第 2 題解出來的主機指到 `0.0.0.0`，再輸入 `sudo verify_block` 取得答案。不可誤封公司或 Microsoft 的正常網域。
- 答案：`metis{cGhpc2hfc2lua2hvbGVk}`（不要勾「忽略大小寫」）
- 提示 1（扣 0.1）：`/etc/hosts` 只有 root 能寫，格式是 `0.0.0.0 <主機名稱>`：`echo "0.0.0.0 <主機名稱>" | sudo tee -a /etc/hosts`。
- 提示 2（扣 0.3）：要封的是解碼後網址的主機，不是 HTML 寫的那個，也不是信裡的連結。寫完用 `getent hosts <主機名稱>` 確認是 0.0.0.0；寫錯用 `sudoedit /etc/hosts` 刪掉。

## 地圖（自訂 32 × 20）
版面在 `map-layout.txt`：大廳（起點、警衛）→ 業務部（t1，第 1 題）→ 門 e1 → SOC 鑑識室（t2，第 2 題）→ 門 e2 → 機房（t3，第 3 題）。
操作：方向鍵走動、E 開門／互動、TAB 工具箱。

## 映像裡有什麼
| 路徑 | 擁有者／權限 | 用途 |
|---|---|---|
| `/home/student/notes.txt` | student / 644 | 值班交接與指令說明 |
| `/home/student/evidence/login.html` | student / 644 | 沙箱存下的釣魚網頁（第 2 題） |
| `/var/mail/student` | student:mail / 660 | 信箱，3 封信，1 封是釣魚信（第 1 題） |
| `/usr/local/sbin/verify_block` | root / 700 | 驗證腳本，答案在裡面，學生讀不到（第 3 題） |
| `/etc/sudoers.d/student` | root / 440 | 只允許 `tee -a /etc/hosts`、`sudoedit /etc/hosts`、`verify_block` |

沒有 CMD：METIS 的 Linux 主機目標會讓容器保持運作，映像自己的 CMD／ENTRYPOINT 不會執行。

## 本機確認
```
docker build -t phishing-lab:dev .
docker run --rm -it -u student -w /home/student phishing-lab:dev bash
```

## 參考解法（約 10 分鐘）
```
cat notes.txt
grep -n -iE '^(subject|from|return-path|x-)|spf=' /var/mail/student      # 第 3 封 spf=fail → metis{aGVhZGVyX3NwZl9mYWls}
grep -n -A3 'atob\|_cfg' ~/evidence/login.html
echo 'aHR0cHM6Ly9zeW5j...' | base64 -d                                   # sync.m365-verify.example → metis{ZGVjb2RlZF9waGlzaF9ob3N0}
echo "0.0.0.0 sync.m365-verify.example" | sudo tee -a /etc/hosts
getent hosts sync.m365-verify.example                                    # 0.0.0.0
sudo verify_block                                                        # metis{cGhpc2hfc2lua2hvbGVk}
```

陷阱：只封信中的 `login.m365-verify.example` 不會過；封 HTML 寫的 `login.microsoftonline.example` 會被判定誤封。
