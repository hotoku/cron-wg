# cron-wg

wg への接続をチェックして、接続が切れていたら再接続するスクリプト。

## 動作

毎分、wireguard のネットワークが生きているかをチェックし、生きていなかったら再接続する。

- ネットワークのチェック: `/var/run/wireguard/wg0.name`があるかどうかをチェックする。
- 再接続: `wg-quick down wg0; wg-quick up wg0;`
  - `down`は不要かもしれないが、一応、ゴミとかが残ってるかもしれないので念の為に実行している

ログは、このディレクトリの`cron.log`に追記する。`cron.log`のオーナーは、hotoku:staff に設定しておく。

`cron-wg.conf`ファイルで、ログローテーションが設定できる。

## 導入方法

### crontab

root の crontab に`check.bash`を定期実行するように設定する。

```shell
sudo su -
crontab -e
```

vi が立ち上がるので、

```crontab
* * * * * /Users/hotoku/projects/hotoku/cron-wg/check.bash
```

を記入する。これで、毎分、`check.bash`が起動する。

### slack incoming webhook

実行時のログを Slack にも送っている。送信先の URL は、`credentials/urls.json`の中に、以下の形式で記述する。

```json
{
  "logs": "https://hooks.slack.com/services/XXXXXX"
}
```

Slack の incoming webhook は、URL が分かると誰でも送信できるので、このファイルは秘密情報として保管する（GitHub に push しない！）。

### ログローテーション

ログローテーションの設定をする。`cron-wg.conf`を`/etc/newsyslog.d`にコピーすれば良い。

```shell
sudo cp cron-wg.conf /etc/newsyslog.d
```
