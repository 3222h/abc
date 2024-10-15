## QuickStart

### 1. username=ubuntu
### 2. password=123456


### 3. build code
```bash
docker build -t abc .
```

### 4. run code
```bash
docker run --restart always -p 3000:3000 --privileged --name nomashine abc
```

### 4. run code
```bash
sudo docker run -d --restart always -e VNC_PASSWORD=12345 -p 6000:80 --name nomashine abc
```
