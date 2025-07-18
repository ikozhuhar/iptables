<p align="center">
<img src="https://github.com/ikozhuhar/iptables/blob/main/img/iptables.jpeg">
</p>

### Команды iptables

| Команды | Описание |
| ------- | ----------- |
| `iptables -L` | просмотр списка правил |
| `iptables -F` | сброс правил (политика остаётся) |
| `iptables -P` | установка политики по умолчанию |
| `iptables -I` | вставить правило в начало списка |
| `iptables -A` | добавить правило в конец списка |
| `iptables -D` | удалить правило |


### Критерии правил в iptables

| Команды | Описание |
| ------- | ----------- |
| `-p` | проколол |
| `-i` | интерфейс источника |
| `-o` | интерфейс назначения |
| `-s` | адрес источника |
| `--dport` | порт назначения |
| `--sport` | порт источника |
| `-m multiport --dports` | несколько портов назначения |
| `-m conntrack --ctstate` | статус соединения (или ранее -m state --state) |
| `--icmp-type` | тип ICMP-сообщения |
| `-j` | действие |



### Действия с пакетами — target, jump (-j)

| Команды | Описание |
| ------- | ----------- |
| `ACCEPT` | разрешить |
| `DROP` | выкинуть |
| `REJECT` | отклонить |
| `REDIRECT` | перенаправить |
| `DNAT/SNAT` | destination/source NAT (network address translation) |
| `LOG` | записать в лог |
| `RETURN` | выйти из цепочки |



:white_check_mark: _Посмотреть правила_

```ruby
# Посмотреть правила
iptables -S
iptables -nvL --line
iptables -nvL INPUT --line
```


:white_check_mark: _Удаление правил_

```ruby
sudo iptables -S
# Допустим в данном выводе мы нашли правило
-A INPUT -i eth0 -p tcp --dport 443 -j ACCEPT
# Удаляем найденное правило
sudo iptables -D INPUT -i eth0 -p tcp --dport 443 -j ACCEPT

# Удаление по номеру правила в цепочке
sudo iptables -vnL --line
# -D имя_цепочки номер
sudo iptables -D INPUT 5

# Удаление всех правил в цепочки INPUT
sudo iptables -F INPUT

# Удаления правил во всех цепочках
sudo iptables -F
```


:white_check_mark: _Правила в определенной позиции_

```ruby
# Поставить правило в седьмую позицию используем ключ -I в правиле
iptables -I INPUT 7 -i eno1 -p tcp -m multiport --dports 8400:8408 -j ACCEPT

# Ставим правило на второе место в списке
iptables -I INPUT 2 -i lo -j ACCEPT

# Поставить правило в конец цепочки 
iptables -A INPUT -i eno1 -p tcp -m multiport --dports 8400:8408 -j ACCEPT
```


:white_check_mark: _Перенаправление_

```ruby
# Трафик tcp на порт 80 перенаправить на порт 8080
iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# Трафик tcp на порт 9022 транслировать на адрес 192.168.56.6 и порт 22
iptables -t nat -A PREROUTING -p tcp --dport 9022 -j DNAT --to 192.168.56.6:22
```

:white_check_mark: _Отклонение трафика_

```ruby
iptables -A INPUT -s 10.26.95.20 -j REJECT --reject-with tcp-reset
iptables -A INPUT -p tcp -j REJECT --reject-with tcp-reset
iptables -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
iptables -A INPUT -j REJECT --reject-with icmp-proto-unreachable
```


:white_check_mark: _Сохранение правил_

```ruby
# Временно
iptables-save > /etc/iptables/rules.v4
sudo netfilter-persistent save

# Постоянно
apt install iptables-persistent netfilter-persistent
netfilter-persistent save
netfilter-persistent start
```


:white_check_mark: _Создание правил_

```ruby
# Разрешить пинг
iptables -A INPUT -p icmp -j ACCEPT
# Запретить ответ на пинг
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# Разрешить трафик на lo интерфейс
iptables -I INPUT -i lo -j ACCEPT

# Разрешить входящий трафик на 22 порт
iptables -A INPUT -p tcp --dport=22 -j ACCEPT

# Разрешаем установленные соединения
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport=80 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -p tcp --dport=443 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports 21,53,6881:6898 -j ACCEPT

# Разрешить весь входящий трафик с определённого IP
iptables -A INPUT -s X.X.X.X -j ACCEPT

# Разрешить весь исходящий трафик на определённый IP
iptables -A OUTPUT -d X.X.X.X -j ACCEPT
```

![image](https://github.com/user-attachments/assets/ae627047-2a90-4dfa-bfc9-ad0601c08e41)


:white_check_mark: _Нормально закрытый файрвол_

```ruby
# ---- INPUT (входящие соединения) ----
sudo iptables -P INPUT DROP                                                                      # политика по умолчанию (default policy)
sudo iptables -A INPUT -i lo -j ACCEPT                                                           # Разрешаем локальный интерфейс
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT                      # Разрешаем локальный интерфейс и established-соединения
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP                                    # Разрешаем локальный интерфейс и established-соединения
sudo iptables -A INPUT -p tcp --dport 22 -s 192.168.1.100 -m conntrack --ctstate NEW -j ACCEPT   # SSH с ограничением по IP (замените 192.168.1.100 на ваш IP)
sudo iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT                    # Веб-серверы
sudo iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT                   # Веб-серверы
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT                                # ICMP (пинг)

# ---- OUTPUT (исходящие соединения) ----
sudo iptables -P OUTPUT ACCEPT                                                                   # политика по умолчанию (default policy)

# ---- FORWARD (транзитные соединения) ----
sudo iptables -P FORWARD DROP                                                                    # политика по умолчанию (default policy)

* -m conntrack - указывает, что правило использует МОДУЛЬ conntrack(connection tracking) для проверки состояния соединения (например, NEW, ESTABLISHED, RELATED, INVALID и др.).
* --ctstate - определяет, какие состояния соединений должны соответствовать правилу (например, NEW, ESTABLISHED, RELATED)

```

### Состояние пакетов

| Команды | Описание |
| ------- | ----------- |
| `NEW` | пакет для создания нового соединения |
| `ESTABLISHED` | пакет, принадлежащий к существующему соединению |
| `RELATED` | пакет для создания нового соединения, но связанный с существующим (например, FTP) |
| `INVALID` | пакет не соответствует ни одному соединению из таблицы |
| `UNTRACKED` | пакет был помечен как неотслеживаемый в таблице raw |



### ipset

```ruby
# Установка ipset
sudo apt install ipset

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
```
![image](https://github.com/user-attachments/assets/85d15123-35ad-4f25-8df1-8989948b1068)



https://interface31.ru/tech_it/2021/02/nastraivaem-port-knocking-v-linux-debian-ubuntu.html
