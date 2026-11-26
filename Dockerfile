# METIS Linux 主機關卡：釣魚郵件分析 + 網域封鎖。平台會讓容器保持運作，所以不需要 CMD。
FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends sudo less nano \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash student \
    && echo 'cd ~' >> /home/student/.bashrc \
    && echo 'export EDITOR=nano' >> /home/student/.bashrc

# 值班交接與沙箱存下的釣魚網頁
COPY --chown=student:student --chmod=0644 home/notes.txt /home/student/notes.txt
COPY --chown=student:student --chmod=0644 home/evidence/login.html /home/student/evidence/login.html
RUN chown student:student /home/student/evidence && chmod 0755 /home/student/evidence

# 信箱：Debian 的標準位置與權限
COPY --chown=student:mail --chmod=0660 mail/student /var/mail/student

# 驗證腳本與 Flag 只有 root 讀得到
COPY --chown=root:root --chmod=0700 verify_block /usr/local/sbin/verify_block

# student 只能：附加寫入 /etc/hosts、用 sudoedit 修改 /etc/hosts、執行驗證腳本
RUN printf '%s\n' \
      'Defaults:student !lecture' \
      'student ALL=(root) NOPASSWD: /usr/bin/tee -a /etc/hosts, sudoedit /etc/hosts, /usr/local/sbin/verify_block' \
      > /etc/sudoers.d/student \
    && chmod 0440 /etc/sudoers.d/student \
    && visudo -cf /etc/sudoers.d/student
