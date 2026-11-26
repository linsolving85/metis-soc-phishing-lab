# metis-soc-phishing-lab

METIS「Linux 主機」關卡：SOC 釣魚郵件鑑識與網域封鎖（初學者友善版，約 10 分鐘）。
只用真實環境的指令：`cat`、`grep`、`base64`、`sudo tee`、`getent`，沒有自製腳本。

Flag 格式統一為 `metis{<base64>}`。情境中的網域都用保留的 `.example`、IP 用 RFC 5737 與私有範圍。

## 映像
`ghcr.io/linsolving85/metis-soc-phishing-lab:v1.0.0`

推 `v*` tag 時由 GitHub Actions 建置並推到 ghcr。完成後把套件可見度設成 Public。

## 在關卡編輯器怎麼填

| 欄位 | 填什麼 |
|---|---|
| 標題 | SOC 事件應變：釣魚郵件鑑識與網域封鎖 |
| 難度／預估時間 | 簡單／10m |
| 標籤 | `linux, soc, phishing, base64` |
| 目標 → 類型 | Linux 主機 |
| 登入使用者／shell | student／/bin/bash |
| 允許 sudo／SUID 提權 | **要勾**（第 3 題要用 sudo 寫 /etc/hosts） |
| 提供攻擊機終端機 | 不勾 |

### 第 1 題：看穿偽造的寄件人（配分 30）
- 地圖位置：業務部受害者電腦（開啟入口）→ 門 e1 作答
- 題目說明：信箱 `/var/mail/student` 裡有 3 封信，其中一封寄件人被偽造成公司 IT。找出它，答案在它的標頭裡。
- 答案：`metis{aGVhZGVyX3NwZl9mYWls}`
- 提示 1（扣 0.1）：偽造的信寄件驗證會失敗，試試 `grep -i spf /var/mail/student`。
- 提示 2（扣 0.3）：`grep -i -A10 'spf=fail' /var/mail/student`，往下看 10 行。

### 第 2 題：找出帳密真正的去向（配分 30）
- 地圖位置：SOC 電腦（開啟入口）→ 門 e2 作答
- 題目說明：沙箱把釣魚頁存成 `~/evidence/login.html`。表單上寫的目的地是 Microsoft，但帳密其實被送到別處。找出真正的網址，答案就在網址裡。
- 答案：`metis{ZGVjb2RlZF9waGlzaF9ob3N0}`
- 提示 1（扣 0.1）：釣魚網頁常用 `atob()` 把網址藏成 base64。試試 `grep atob ~/evidence/login.html`。
- 提示 2（扣 0.3）：把 `atob("...")` 引號裡的字串複製下來，執行 `echo '字串' | base64 -d`。

### 第 3 題：封鎖釣魚網域（配分 40）
- 地圖位置：機房主控台（開啟入口）→ 旁邊作答電腦
- 題目說明：把第 2 題找到、真正收帳密的網域加進 `/etc/hosts` 指到 `0.0.0.0` 封鎖它，用 `getent hosts` 確認。最後把封鎖的網域用 base64 編碼後放進 `metis{}` 回報。
- 答案：`metis{c3luYy5tMzY1LXZlcmlmeS5leGFtcGxl}`
- 提示 1（扣 0.1）：封鎖：`echo "0.0.0.0 網域" | sudo tee -a /etc/hosts`，確認：`getent hosts 網域` 會回 0.0.0.0。
- 提示 2（扣 0.3）：要封的是 `base64 -d` 解出來的網域，不是信裡的連結。編碼：`echo -n 網域 | base64`，`-n` 不能省。

## 地圖（自訂 32 × 20）
版面在 `map-layout.txt`：大廳（起點、警衛）→ 業務部（t1，第 1 題）→ 門 e1 → SOC 鑑識室（t2，第 2 題）→ 門 e2 → 機房（t3，第 3 題）。
操作：方向鍵走動、E 開門／互動、TAB 工具箱。

## 映像裡有什麼
| 路徑 | 擁有者／權限 | 用途 |
|---|---|---|
| `/home/student/notes.txt` | student / 644 | 值班交接與指令說明 |
| `/var/mail/student` | student:mail / 660 | 信箱，3 封信，1 封是釣魚信（第 1 題） |
| `/home/student/evidence/login.html` | student / 644 | 沙箱存下的釣魚網頁（第 2 題） |
| `/etc/sudoers.d/student` | root / 440 | 只允許 `sudo tee -a /etc/hosts`（第 3 題） |

沒有 CMD：METIS 的 Linux 主機目標會讓容器保持運作。

## 參考解法
```
cat notes.txt
grep -i -A10 'spf=fail' /var/mail/student                     # metis{aGVhZGVyX3NwZl9mYWls}
grep atob ~/evidence/login.html
echo 'aHR0cHM6Ly9zeW5j...' | base64 -d                       # metis{ZGVjb2RlZF9waGlzaF9ob3N0}
echo "0.0.0.0 sync.m365-verify.example" | sudo tee -a /etc/hosts
getent hosts sync.m365-verify.example                        # 0.0.0.0
echo -n sync.m365-verify.example | base64                    # metis{c3luYy5tMzY1LXZlcmlmeS5leGFtcGxl}
```

陷阱：第 1 題的 Microsoft 英文通知是正常信；第 2 題 `action=` 寫的 Microsoft 網址是假的目的地；第 3 題封信裡連結的 login.m365-verify.example 是錯的。
平台只檢查答案，無法確認學生真的改了 /etc/hosts；封鎖步驟寫在題目說明裡當作必做流程。
