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

Примеры:
```ruby
# Посмотреть правила
iptables -nvL --line
iptables-save

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

# Отклонить трафик и вернуть сообщение
iptables -A INPUT -s 10.26.95.20 -j REJECT --reject-with tcp-reset
iptables -A INPUT -p tcp -j REJECT --reject-with tcp-reset
iptables -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
iptables -A INPUT -j REJECT --reject-with icmp-proto-unreachable

# Трафик tcp на порт 80 перенаправить на порт 8080
iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# Трафик tcp на порт 9022 транслировать на адрес 192.168.56.6 и порт 22
iptables -t nat -A PREROUTING -p tcp --dport 9022 -j DNAT --to 192.168.56.6:22

# Ставим правило на второе место в списке
iptables -I INPUT 2 -i lo -j ACCEPT

# Удаляем правило. Сначала смотрим номер, а далее по номеру удаляем
iptables -nvL --line
iptables -D INPUT 9

```
![image](https://github.com/user-attachments/assets/ae627047-2a90-4dfa-bfc9-ad0601c08e41)


### Состояние пакетов

| Команды | Описание |
| ------- | ----------- |
| `NEW` | пакет для создания нового соединения |
| `ESTABLISHED` | пакет, принадлежащий к существующему соединению |
| `RELATED` | пакет для создания нового соединения, но связанный с существующим (например, FTP) |
| `INVALID` | пакет не соответствует ни одному соединению из таблицы |
| `UNTRACKED` | пакет был помечен как неотслеживаемый в таблице raw |


### Сохранение правил в iptables

_Временно:_
```ruby
iptables-save > ./iptables.rules
iptables-restore < ./iptables.rules
```

_Постоянно🥇
```ruby
apt install iptables-persistent netfilter-persistent
netfilter-persistent save
netfilter-persistent start
```
