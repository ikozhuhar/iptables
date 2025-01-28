# Сетевой фильтр

# Рассмотрим подробнее команды iptables. Говоря в общем, iptables — утилита, 
# задающая правила для сетевого фильтра Netfilter и работающая в пространстве 
# ядра Linux.

man iptables
man iptables-extentions

# -L — посмотреть список правил (можно указать цепочку, иначе выводятся все);
sudo iptables -nvL --line

# -P — установить политику по умолчанию для заданной цепочки;
sudo iptables -P INPUT DROP
# или
sudo iptables -P INPUT ACCEPT

# Политика по умолчанию задает порядок работы с пакетами, для которых нет ни 
# одного правила. Если в цепочке правил ни одно не подошло, в итоге применяется 
# действие по умолчанию, которое и задается политикой. Если правило подошло, 
# действие по умолчанию не выполняется.

# Цепочка — это набор правил, которые проверяются по пакетам поочередно 
# (напоминает язык программирования). В таблице filter видим цепочки INPUT, 
# FORWARD и OUTPUT. Но есть и другие таблицы (их нужно указывать явно): таблица 
# nat, когда нам необходима трансляция адресов и портов, и mangle — когда 
# требуется внести изменения в пакет (например, установить ttl в 64 и скрыть от 
# провайдера использование подключения как шлюза к собственной сети).

#Просмотреть цепочки для другой таблицы
iptables -t nat -L
iptables -t nat -nvL --line-numbers      
      
      
# Обратите внимание: имеет значение порядок правил в цепочке. Сравните:
iptables -A INPUT -p tcp -j DROP
iptables -A INPUT -p tcp --dport=22 -m conntrack --ctstate NEW -j ACCEPT

# Просмотреть таблицу соединений (apt install conntrack)
conntrack -L
# Просмотр событий по conntrack
conntrack -E


# Простой пример конфигурации:

iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

iptables -A INPUT -i lo -j ACCEPT 
iptables -A OUTPUT -o lo -j ACCEPT

iptables -A INPUT -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT

# Заблокиривать запросы ping
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# Локальные соединения с динамических портов
iptables -A OUTPUT -p TCP --sport 32768:61000 -j ACCEPT
iptables -A OUTPUT -p UDP --sport 32768:61000 -j ACCEPT

# Разрешить только те пакеты, которые мы запросили
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Дропаем невалидные пакеты
iptables -A INPUT -i enp0s3 -m conntrack --ctstate INVALID -j DROP

# Варианты REJECT
iptables -A INPUT -s 10.26.95.20 -j REJECT --reject-with tcp-reset
iptables -A INPUT -p tcp -j REJECT --reject-with tcp-reset 
iptables -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
iptables -A INPUT -j REJECT --reject-with icmp-proto-unreaсhable

# Но если работаем как сервер, следует разрешить и нужные порты
iptables -A INPUT -i enp0s3 -p TCP --dport 22 -j ACCEPT 
iptables -A OUTPUT -o enp0s3 -p TCP --sport 22 -j ACCEPT

# Несколько портов
iptables -A INPUT -p tcp -m multiport --dports 21,22,6881:6882 -j ACCEPT

# Редирект порта
iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# Логирование (в /var/log/kern.log и journalctl)
iptables -A INPUT -s 192.168.11.0/24 -j LOG --log-prefix='[netfilter] '
iptables -A INPUT -p ipmp -j LOG --log-prefix='[icmp] '

# Ограничение частоты подключений
# Сохраняем IP с недавними подключениями для динамического списка
iptables -I INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
# Принимаем не более 10 подключений с одного IP в течение 120 секунд
iptables -I INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 120 --hitcount 10 -j DROP

# Ограничение подключений к веб-серверу
# Разрешаем установленные соединения
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# Разрешаем не более 20 подключений в минуту на 80 и 443 порты
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -m limit --limit 20/min --limit-burst 30 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -m limit --limit 20/min --limit-burst 30 -j ACCEPT

# Логируем те, которые не прошли лимит:
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -m limit --limit 20/min --limit-burst 30 -j LOG --log-prefix='[conn drop] '

# Дропаем все остальные подключения
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j DROP
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j DROP

# Ограничение пропускной способности (исходящей)
# Добавляем цепочку
iptables -N RATE_LIMIT
# Разрещаем трафик в рамках лимита
iptables -A RATE_LIMIT -m limit --limit 1mbit/s -j ACCEPT
# Остальное дропаем
iptables -A RATE_LIMIT -j DROP
# Добавляем редирект на цепочку из OUTPUT
iptables -A OUTPUT -o eth0 -j RATE_LIMIT

# Ограничение по количеству пакетов
iptables -A OUTPUT -m limit --limit 10/s -j ACCEPT
iptables -A INPUT -m tcp -p tcp --dport 80 -m conntrack --ctstate RELATED,ESTABLISHED -m limit --limit 10/second -j ACCEPT

# Сохранение и восстановление значений
iptables-save > ./iptables.rules
iptables-restore < ./iptables.rules

# Маркировка трафика (только таблица mangle)
iptables -t mangle -A PREROUTING -p tcp --dport 22 -j MARK --set-mark 2
iptables -A INPUT -m mark --mark 2 -j DROP
# https://www.linuxtopia.org/Linux_Firewall_iptables/x4368.html
# https://unix.stackexchange.com/questions/467076/how-set-mark-option-works-on-netfilter-iptables

iptables -A INPUT -s 209.175.153.23 -j DROP
iptables -A INPUT -s 209.175.153.23 -p tcp --destination-port 22 -j DROP

# Локальный редирект порта
iptables -t nat -A PREROUTING -p tcp --dport 5555 -j REDIRECT --to-port 22
iptables -t nat -A OUTPUT -p tcp -s 127.0.0.1 --dport 5555 -j REDIRECT --to-ports 22
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -t mangle -A PREROUTING -p tcp --dport 22 -j DROP
iptables -P INPUT DROP

# Работа с NAT - проброс порта на другой хост
iptables -t nat -A PREROUTING -p tcp --dport 9022 -j DNAT --to 192.168.56.6:22
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
iptables -A FORWARD -p tcp -d 192.168.56.6 --dport 22 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

iptables -A FORWARD -i enp0s8 -o enp0s3 -j ACCEPT

# NAT Host
echo 1 > /proc/sys/net/ipv4/ip_forward

# Edit systctl.conf for permanent changes
# MASQUERADE = auto SNAT
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
iptables -A FORWARD -i enp0s8 -o enp0s3 -j ACCEPT

# Сохранение правил
apt install iptables-persistent netfilter-persistent
netfilter-persistent save
netfilter-persistent start

## IPSet
# Создать (отдельные IP)
ipset -N ddos iphash

# Создать (подсети)
ipset create blacklist nethash

# Добавить подсеть
ipset -A ddos 109.95.48.0/21

# Посмотреть список
ipset -L ddos

# Проверить
ipset test ddos 185.174.102.1

# Сохранение
sudo ipset save blacklist -f ipset-blacklist.backup

# Восстановление
sudo ipset restore -! < ipset-blacklist.backup

# Очистка
sudo ipset flush blacklist

# Правило
iptables -I PREROUTING -t raw -m set --match-set ddos src -j DROP

# Сохранение постоянно
apt install ipset-persistent

# Трейсинг правил
iptables -A PREROUTING -t raw -p tcp -j TRACE
xtables-monitor -t

# Собственные цепочки
# Определим цепочку для входящего SSH, укажем там только нужные хосты
iptables -N chain-incoming-ssh
iptables -A chain-incoming-ssh -s 192.168.1.148 -j ACCEPT
iptables -A chain-incoming-ssh -s 192.168.122.1 -j ACCEPT
iptables -A chain-incoming-ssh -j DROP

# Создадим цепочку для установленных соединений
iptables -N chain-states
iptables -A chain-states -p tcp  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A chain-states -p udp  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A chain-states -p icmp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A chain-states -j RETURN

# Дропаем некорректные пакеты
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Разрешаем входящие пакеты установленных соединений
iptables -A INPUT  -j chain-states

# Разрешаем входящий SSH с использованием цепочки
iptables -A INPUT -p tcp --dport 22 -j chain-incoming-ssh

# Логирование iptables в отдельный файл
https://habr.com/ru/articles/259169/

# conntrck and stat modules: conntrack is new
https://superuser.com/questions/1071656/whats-the-difference-between-iptables-state-and-ctstate
