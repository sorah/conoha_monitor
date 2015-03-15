# conoha_monitor - report ConoHa information.aspx to fluentd

## Usage

```
$ env CONOHA_MONITOR_TAG_PREFIX=conoha-monitor CONOHA_MONITOR_FLUENTD=localhost:24224 ruby conoha_monitor.rb
```

### Docker

- repo: https://quay.io/repository/sorah/conoha_monitor
  - built on Circle CI: [![Circle CI](https://circleci.com/gh/sorah/conoha_monitor.svg?style=svg)](https://circleci.com/gh/sorah/conoha_monitor)

```
docker run -e CONOHA_MONITOR_FLUENTD=your-fluentd-host:24224 quay.io/sorah/conoha_monitor:latest
```

#### Tips

If you're running fluentd on docker host, you can pass `docker0` interface's IPv4 address as environment variable:

```
-e CONOHA_MONITOR_FLUENTD=$(ip a show dev docker0|grep 'inet '|awk '{print $2}'|cut -d/ -f1):24224
```

make sure accept connection from `docker0`: `sudo iptables -A INPUT -p tcp --dport 24224 -i docker0 -j ACCEPT`

## License

MIT License
