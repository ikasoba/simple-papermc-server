# usage
```sh
docker run --rm -it -e EULA=true -p 25565:25565 -v ./mc:/home/mc local-sps:latest
```

# /home/mc
papermcが使うディレクトリ、データの永続化やらはここへのボリュームを作ればいい感じ
