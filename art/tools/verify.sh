#!/bin/zsh
# 逐像素比對：verify.sh 設計.txt 匯出.png → 印出差異格數（Pixelorama 的 import_image 偶爾會掉像素）
d=$1; p=$2
sed 1d "$d" | awk '{print $1,$3}' | sed 's/#[0-9A-F]\{6\}00$/#00000000/' > /tmp/pixv_d.$$
magick "$p" txt:- | sed 1d | awk '{print $1,$3}' | sed 's/#\([0-9A-F]\{6\}\)$/#\1FF/; s/#[0-9A-F]\{6\}00$/#00000000/' > /tmp/pixv_p.$$
n=$(diff /tmp/pixv_d.$$ /tmp/pixv_p.$$ | grep -c '^>')
echo "$(basename $p): $n 格不同"
rm -f /tmp/pixv_d.$$ /tmp/pixv_p.$$
